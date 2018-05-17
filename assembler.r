# /usr/bin/r
#
# staples together various campground files,
# interpreting the data nicely.
# 
# later on we will attach weather data.
#
# Created: 2017.04.29
# Copyright: Steven E. Pav, 2017-2018
# Author: Steven E. Pav <steven@gilgamath.com>
# Comments: Steven E. Pav

suppressMessages(library(docopt))       # we need docopt (>= 0.3) as on CRAN

doc <- "Usage: assembler.r [-v] [--homelat <HOMELAT>] [--homelon <HOMELON>] [-O <OUTFILE>] [INFILES...]

-O OUTFILE --outfile=OUTFILE     Give the output file [default: all.csv]
--homelat=HOMELAT                Latitude for home [default: 37.7749]
--homelon=HOMELON                Longitude for home (negative for northern hemi?) [default: -122.4194]
-v --verbose                     Be more verbose
-h --help                        show this help text"

opt <- docopt(doc)

suppressMessages({
	library(readr)
	library(dplyr)
	library(tidyr)
	library(magrittr)
	library(lubridate)
	library(geosphere)
})

# opt <- docopt(doc,args='uscampgrounds/CanadaCamp.csv uscampgrounds/MidwestCamp.csv uscampgrounds/NortheastCamp.csv uscampgrounds/SouthCamp.csv uscampgrounds/SouthwestCamp.csv uscampgrounds/WestCamp.csv')
# from
# http://www.uscampgrounds.info/takeit.html
# 
# The fields in the below .csv files are in this order: lon, lat, gps composite field (ie: all the following data fields compacted into one field for a single-field GPS or mapping software display), 4 letter campground code (corresponds to map), campground name, type, phone, dates open, comments (COMM), number of campsites, elevation (feet), amenities (AMEN), state, distance and bearing from nearest town.  
loadone <- function(fname) {
	require(readr,quietly=TRUE)
	require(dplyr,quietly=TRUE)
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
		mutate(toilets=case_when(grepl('FTVT',.$amenities) ~'flush_and_vault',
														 grepl('FT',.$amenities) ~'flush',
														 grepl('VT',.$amenities) ~'vault',
														 grepl('PT',.$amenities) ~'pit',
														 grepl('NT',.$amenities) ~'none',
														 TRUE ~ NA_character_),
					 drinking_water=case_when(grepl('DW',.$amenities) ~ TRUE,
																		grepl('NW',.$amenities) ~ FALSE,
																		TRUE ~ NA),
					 reservations=case_when(grepl('RS',.$amenities)~TRUE,
																	grepl('NR',.$amenities)~FALSE,
																	TRUE ~ NA),
					 showers=case_when(grepl('SH',.$amenities) ~TRUE,
														 grepl('NS',.$amenities) ~FALSE,
														 TRUE ~ NA)) %>%
		mutate(phone_number=gsub('^-+|-+$','',gsub('[^0-9/;a-zA-Z]','-',phone_number))) %>%
		mutate(dates_open=gsub('ealry','early',dates_open)) %>%
		mutate(dates_open=gsub('\\s*-\\s*','-',dates_open)) 
		

	# interpret dates_open to weeks
	dopens <- outdat %>% 
		distinct(dates_open) %>%
		mutate(foo_open=dates_open) %>%
		mutate(foo_open=gsub('-\\s*$','-late dec',foo_open)) %>%
		mutate(foo_open=gsub('early','05',foo_open)) %>%
		mutate(foo_open=gsub('mid','15',foo_open)) %>%
		mutate(foo_open=gsub('late','25',foo_open)) %>%
		mutate(start=case_when(grepl('all year',.$foo_open) ~ '03 jan',
													 grepl('closed summer months',.$foo_open) ~ '21 sep',
													 TRUE ~ gsub('^(.+)-.+','\\1',.$foo_open))) %>%
		mutate(end=case_when(grepl('all year',.$foo_open) ~ '29 dec',
													 grepl('closed summer months',.$foo_open) ~ '21 jun',
													 TRUE ~ gsub('^.+-(.+)$','\\1',.$foo_open))) %>%
		mutate(start=as.Date(paste0(start,' 2017'),format='%d %b %Y'),
					 end=as.Date(paste0(end,' 2017'),format='%d %b %Y')) %>%
		mutate(start_week=lubridate::epiweek(start),
					 end_week=lubridate::epiweek(end)) 

	outdat %<>%
		left_join(dopens %>% select(dates_open,start_week,end_week),by='dates_open') %>%
		rename(opening_week=start_week,
					 closing_week=end_week)

	# go metric
	outdat %<>%
		mutate(elevation_m=round(0.3048*elevation_ft)) %>% select(-elevation_ft) %>%
		mutate(distance_to_town_km=round(1.60934*distance_to_town,digits=2)) %>% select(-distance_to_town)

	outdat
}

outdat <- lapply(opt$INFILES,loadone) %>%
	bind_rows() 

# sort by distance from 'home'
#home_lonlat <- as.numeric(c(opt$homelon,opt$homelat))
#outdat %<>%
	#mutate(dist_home_km = round(1e-3 * geosphere::distGeo(home_lonlat,matrix(c(lon,lat),ncol=2) ),digits=2)) %>%
	#arrange(dist_home_km) %>% 
	#select(-dist_home_km)

# write output
outdat %>% 
	write_csv(opt$outfile)

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
