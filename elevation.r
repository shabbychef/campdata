# /usr/bin/r
#
# infers missing elevations from the usgs website 
#
# Created: 2018.05.16
# Copyright: Steven E. Pav, 2018
# Author: Steven E. Pav <steven@gilgamath.com>
# Comments: Steven E. Pav

suppressMessages(library(docopt))       # we need docopt (>= 0.3) as on CRAN

doc <- "Usage: elevations.r [-v] INFILE OUTFILE

-v --verbose                     Be more verbose
-h --help                        show this help text"

opt <- docopt(doc)

suppressMessages({
	library(readr)
	library(dplyr)
	library(tidyr)
	library(tibble)
	library(magrittr)
	library(XML)
	library(stringr)
	library(RCurl)
})

# do lookup, with fallbacks, to USGS and canadian equivalent# FOLDUP
options(digits=9)

# https://www.nrcan.gc.ca/earth-sciences/geography/topographic-information/free-data-geogratis/geogratis-web-services/api/17328
cdem_lookup_elevation <- function(lon,lat) {
	require(jsonlite,quietly=TRUE)
	require(stringr,quietly=TRUE)
	require(RCurl,quietly=TRUE)
	result <- tryCatch({
		url <- stringr::str_interp('http://geogratis.gc.ca/services/elevation/cdem/altitude?lat=${lat}&lon=${lon}')
		xData <- getURL(url)
		data <- jsonlite::fromJSON(xData)
		reply <- as.numeric(data$altitude)
		reply <- ifelse(is.na(reply) || (reply < -1000),NA_real_,reply)
	},error=function(e) {
		print(e)
		NA_real_
	})
	result
}
usgs_lookup_elevation <- function(lon,lat) {
	require(XML,quietly=TRUE)
	require(stringr,quietly=TRUE)
	require(RCurl,quietly=TRUE)
	options(digits=9)
	result <- tryCatch({
		url <- stringr::str_interp('https://nationalmap.gov/epqs/pqs.php?x=${lon}&y=${lat}&units=Meters&output=xml')
		xData <- getURL(url)
		data <- xmlParse(xData)
		xml_data <- xmlToList(data)
		reply <- as.numeric(xml_data$Elevation_Query$Elevation)
		reply <- ifelse(is.na(reply) || (reply < -1000),NA_real_,reply)
	},error=function(e) {
		print(e)
		NA_real_
	})
	result
}
lookup_elevation <- function(lon,lat) {
	cat('looking up ',lon,lat,'...')
	if (lat > 49) {
		result <- cdem_lookup_elevation(lon,lat)
		if (is.na(result)) {
			result <- usgs_lookup_elevation(lon,lat)
		}
	} else {
		result <- usgs_lookup_elevation(lon,lat)
		if (is.na(result)) {
			result <- cdem_lookup_elevation(lon,lat)
		}
	}
	cat(result,'\n')
	result
}

#fooz <- lookup_elevation(lon=-72.954,lat=40.952)
#fooz <- lookup_elevation(lon=-72.954,lat=52.952)

lookup_many <- function(adf) {
	require(tibble,quietly=TRUE)
	weirdo <- adf %>%
		filter(is.na(elevation_m)) %>%
		select(lon,lat) %>%
		distinct(lon,lat) %>%
		tibble::rowid_to_column() %>%
		group_by(rowid) %>%
			mutate(lookup_elevation_m=lookup_elevation(lon=lon,lat=lat)) %>%
		ungroup() %>%
		select(-rowid)
}
# UNFOLD

# load the infile
indat <- readr::read_csv(opt$INFILE) 

lookup_us <- indat %>%
	filter(is.na(elevation_m)) %>%
	select(lat,lon,elevation_m) %>%
	distinct(lat,lon,.keep_all=TRUE)

if (file.exists(opt$OUTFILE)) {
	prevrun <- readr::read_csv(opt$OUTFILE) %>%
		select(lat,lon,lookup_elevation_m)
	lookup_us %<>% 
		anti_join(prevrun %>% filter(!is.na(lookup_elevation_m)),by=c('lat','lon'))
} 

if (nrow(lookup_us) > 0) {
	system.time({
		lookmore <- lookup_us %>%
			lookup_many()
	})

# did these by hand:
# from  https://www.freemaptools.com/elevation-finder.htm
	lookmore %<>%
		filter(!is.na(lookup_elevation_m)) %>%
		rbind(tibble::tribble(~lat,    ~lon,     ~lookup_elevation_m,
	57.763, -152.478,                32.2, 
	57.831, -152.360,                 19.1,
	68.500, -149.460,               874.8,
	67.318, -150.163,                336.4))

	if (file.exists(opt$OUTFILE)) {
		result <- prevrun %>%
			left_join(lookmore %>% rename(new_elevation=lookup_elevation_m),by=c('lat','lon')) %>%
			mutate(lookup_elevation_m=coalesce(lookup_elevation_m,new_elevation)) 
	} else {
		result <- lookmore
	}

	result %<>%
		select(lat,lon,lookup_elevation_m) %>%
		distinct(lat,lon,.keep_all=TRUE) %>%
		arrange(lat,lon)

	result %>%
		readr::write_csv(opt$OUTFILE)
} else {
	warning('nothing to look up!')
}

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
