# /usr/bin/r
#
# Created: 2017.04.29
# Copyright: Steven E. Pav, 2017
# Author: Steven E. Pav <steven@gilgamath.com>
# Comments: Steven E. Pav

suppressMessages(library(docopt))       # we need docopt (>= 0.3) as on CRAN

doc <- "Usage: converter.r [-v] [--homelat <HOMELAT>] [--homelon <HOMELON>] [-O <OUTFILE>] [INFILES...]

-O OUTFILE --outfile=OUTFILE     Give the output file [default: all.csv]
--homelat=HOMELAT                Latitude for home [default: 37.7749]
--homelon=HOMELON                Longitude for home (negative for northern hemi?) [default: -122.4194]
-v --verbose                     Be more verbose
-h --help                        show this help text"

opt <- docopt(doc)

suppressMessages(library(readr))
suppressMessages(library(dplyr))

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

	outdat
}

home_latlon <- as.numeric(c(opt$homelat,opt$homelon))
suppressMessages(library(geosphere))

outdat <- lapply(opt$INFILES,loadone) %>%
	bind_rows() %>%
	mutate(dist_home_km = 1e-3 * geosphere::distGeo(rev(home_latlon),matrix(c(lon,lat),ncol=2) )) %>%
	arrange(dist_home_km)
		
outdat %>% 
	write_csv(opt$outfile)

#fooz <- outdat %>% 
	#filter(toilets %in% c('flush','flush_and_vault'),
				 #drinking_water & showers & reservations,
				 #state=='CA',type != 'MIL') %>%
	#arrange(desc(lat)) %>%
	#mutate(sf_dist_km = 1e-3 * geosphere::distGeo(rev(home_latlon),matrix(c(lon,lat),ncol=2) )) %>%
	#arrange(sf_dist_km)

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
