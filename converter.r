# /usr/bin/r
#
# Created: 2017.04.29
# Copyright: Steven E. Pav, 2017
# Author: Steven E. Pav <steven@gilgamath.com>
# Comments: Steven E. Pav

suppressMessages(library(docopt))       # we need docopt (>= 0.3) as on CRAN

doc <- "Usage: converter.r [-v] [--station_file <STATIONFILE>] [--ok_station_list <AFILE>] [--homelat <HOMELAT>] [--homelon <HOMELON>] [-O <OUTFILE>] [INFILES...]

-O OUTFILE --outfile=OUTFILE     Give the output file [default: all.csv]
--homelat=HOMELAT                Latitude for home [default: 37.7749]
--homelon=HOMELON                Longitude for home (negative for northern hemi?) [default: -122.4194]
--station_file=STATIONFILE       Give the station file to lookup weather stations. [default: ghcnd-stations.txt]
--ok_station_list=AFILE          Give the csv of the list of OK STATIONs in the STATIONFILE. [default: ok_stations.csv]
-v --verbose                     Be more verbose
-h --help                        show this help text"

opt <- docopt(doc)

suppressMessages({
	library(readr)
	library(dplyr)
	library(tidyr)
})

# opt <- docopt(doc,args='CanadaCamp.csv  SouthwestCamp.csv  WestCamp.csv')

# from
# http://www.uscampgrounds.info/takeit.html
# 
# The fields in the below .csv files are in this order: lon, lat, gps composite field (ie: all the following data fields compacted into one field for a single-field GPS or mapping software display), 4 letter campground code (corresponds to map), campground name, type, phone, dates open, comments (COMM), number of campsites, elevation (feet), amenities (AMEN), state, distance and bearing from nearest town.  
loadone <- function(fname) {
	require(readr)
	require(dplyr)
	col_t <- readr::cols(
		lon = col_double(),
		lat = col_double(),
		gps_composite = col_character(),
		campground_code = col_character(),
		campground_name = col_character(),
		type = col_character(),
		phone_number = col_character(),
		dates_open = col_character(),
		comments = col_character(),
		num_campsite = col_integer(),
		elevation_ft = col_integer(),
		amenities = col_character(),
		state = col_character(),
		distance_to_town = col_double(),
		bearing_to_town = col_character(),
		nearest_town = col_character()
	)
	indat <- readr::read_csv(fname,col_types=col_t,col_names=c('lon','lat','gps_composite','campground_code','campground_name','type',
																			'phone_number','dates_open','comments','num_campsite',
																		 'elevation_ft','amenities','state',
																		 'distance_to_town','bearing_to_town','nearest_town'))

	outdat <- indat %>% 
		select(-gps_composite) %>%
		mutate(toilets=ifelse(grepl('FTVT',amenities),'flush_and_vault',
													ifelse(grepl('FT',amenities),'flush',
																 ifelse(grepl('VT',amenities),'vault',
																				ifelse(grepl('PT',amenities),'pit',
																							 ifelse(grepl('NT',amenities),'none',NA))))),
					 drinking_water=ifelse(grepl('DW',amenities),TRUE,ifelse(grepl('NW',amenities),FALSE,NA)),
					 reservations=ifelse(grepl('RS',amenities),TRUE,ifelse(grepl('NR',amenities),FALSE,NA)),
					 showers=ifelse(grepl('SH',amenities),TRUE,ifelse(grepl('NS',amenities),FALSE,NA))) %>%
		mutate(phone_number=gsub('^-+|-+$','',gsub('[^0-9/;a-zA-Z]','-',phone_number))) 

# go metric
	outdat <- outdat %>%
		mutate(elevation_m=round(0.3048*elevation_ft)) %>% select(-elevation_ft) %>%
		mutate(distance_to_town_km=round(1.60934*distance_to_town,digits=2)) %>% select(-distance_to_town)

	outdat
}


outdat <- lapply(opt$INFILES,loadone) %>%
	bind_rows() 

# sort by distance from 'home'
home_latlon <- as.numeric(c(opt$homelat,opt$homelon))
suppressMessages(library(geosphere))
outdat <- outdat %>%
	mutate(dist_home_km = round(1e-3 * geosphere::distGeo(rev(home_latlon),matrix(c(lon,lat),ncol=2) ),digits=2)) %>%
	arrange(dist_home_km) %>% select(-dist_home_km)

#' lat and lon to xyz
ll_toxyz <- function(myll) {
	convo <- pi / 180
	xyz <- matrix(0,nrow=nrow(myll),ncol=3)
	# in radians
	myll <- convo * myll
	xyz[,3] <- sin(myll[,1])
	cothv  <- cos(myll[,1])
	xyz[,2] <- cothv * cos(myll[,2])
	xyz[,1] <- cothv * sin(myll[,2])
	xyz
}

#' @param centers_ll a \code{n} by 2 matrix of latitude, longitude
#' of the center points.
#' @param findus_ll a \code{m} by 2 matrix of latitude, longitude
#' of the points to lookup.
#' @return an \code{m} vector of indices, in the range 1 to \code{n}
#' giving the index of the center closest to the given findus.
#' we search in Euclidian space first.
#' @note as a former computational geometer, I am utterly *ashamed*
#' of this code.
minidx <- function(centers_ll,findus_ll) {
	centers_xyz <- ll_toxyz(centers_ll)
	findus_xyz <- ll_toxyz(findus_ll)
	retv <- matrix(rep(0,nrow(findus_xyz)),ncol=1)
	for (iii in 1:nrow(findus_xyz)) {
		dels <- colSums((findus_xyz[iii,] - t(centers_xyz))^2)
		retv[iii] <- which.min(dels)
	}
	retv
}

add_closest_station <- function(outdat,stations) {
	require(geosphere)
	centers_ll <- matrix(c(stations$lat,stations$lon),ncol=2)
	findus_ll <- matrix(c(outdat$lat,outdat$lon),ncol=2)
	closest_idx <- minidx(centers_ll,findus_ll)
	outdat$station_code <- stations[closest_idx,]$station
	outdat$station_elevation <- round(stations[closest_idx,]$elevation)

	nearest_lonlat <- matrix(c(stations[closest_idx,]$lon,stations[closest_idx,]$lat),ncol=2)
	distkm <- rep(0,nrow(outdat))
	for (iii in 1:nrow(outdat)) {
		distkm[iii] <- 1e-3 * geosphere::distGeo(c(outdat[iii,]$lon,outdat[iii,]$lat),nearest_lonlat[iii,])
	}
	outdat$station_dist_km <- round(distkm,digits=2)
	outdat
}

if (nchar(opt$station_file) > 0) {
	stations <- readr::read_fwf(opt$station_file,
															col_positions=readr::fwf_widths(c(12,9,9,7,3,31,4,4,4)))
	colnames(stations) <- c('station','lat','lon','elevation','state','location_name','GSN_flag','HCN_flag','WMO_ID')
	stations <- stations %>%
		filter(!is.na(lat),!is.na(lon)) %>%
		filter(lat > 0,lon < 0)

	# whitelist them
	if (nchar(opt$ok_station_list) > 0) {
		ok_stations <- readr::read_csv(opt$ok_station_list) %>%
			rename(station=STATION)

		stations <- stations %>%
			inner_join(ok_stations)
	}

	outdat <- add_closest_station(outdat,stations)
}

outdat %>% 
	write_csv(opt$outfile)

## borken borken borken

#get_closest_station <- function(lat,lon) {
	#require(geosphere)
	#if (is.na(lat) || is.na(lon)) {
		#retval <- NA_character_
	#} else {
		##dists <- 1e-3 * geosphere::distGeo(c(lon,lat),matrix(c(stations$lon,stations$lat),ncol=2))
		##dists <- 1e-3 * geosphere::distGeo(c(lon,lat),statfu)
		##dists <- 1e-3 * geosphere::distGeo(c(lat,lon),revfu)
		##dists <- 1e-3 * geosphere::distCosine(c(lat,lon),revfu)
		##dists <- 1e-3 * geosphere::distHaversine(c(lat,lon),revfu)
		#dists <- 1e-3 * geosphere::distHaversine(c(lon,lat),statfu)
		#iii <- which.min(dists)
		#print(stations[iii,])
		#retval <- stations[iii,]$station
	#}
	#retval
#}


#require(tidyr)
#blahz <- outdat %>%
	#group_by(lat,lon) %>%
		#mutate(staty=list(get_closest_station(lat,lon))) %>%
	#ungroup() %>%
	#tidyr::unnest()

# junkyard
#fooz <- outdat %>% 
	#filter(toilets %in% c('flush','flush_and_vault'),
				 #drinking_water & showers & reservations,
				 #state=='CA',type != 'MIL') %>%
	#arrange(desc(lat)) %>%
	#mutate(sf_dist_km = 1e-3 * geosphere::distGeo(rev(home_latlon),matrix(c(lon,lat),ncol=2) )) %>%
	#arrange(sf_dist_km)
#
## takes forever. screw that.
#require(rwunderground)
#resu <- history_range(set_location(lat_long=paste0(home_latlon,collapse=',')), "20140101", "20161231")

#outdat <- readr::read_csv('all.csv')


#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
