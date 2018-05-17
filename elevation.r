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

indat <- readr::read_csv(opt$INFILE) 

weirdo <- indat %>%
	filter(is.na(elevation_m)) %>%
	select(lon,lat,campground_code,campground_name)

lookup_elevation <- function(lon,lat) {
	require(XML)
	require(stringr)
	require(RCurl)
	cat('looking up ',lon,lat,'...')
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
	cat(result,'\n')
	
	result
}
#fooz <- lookup_elevation(lon=-72.954,lat=40.952)
options(digits=9)

	#sample_n(20) %>%

hasem <- weirdo %>%
	filter(!is.na(lon),!is.na(lat)) %>%
	tibble::rowid_to_column() %>%
	group_by(rowid,campground_name,campground_code) %>%
		mutate(elevation_m=lookup_elevation(lon=lon,lat=lat)) %>%
	ungroup()

indat %<>%
	left_join(hasem %>% select(-rowid) %>% rename(inferred_el=elevation_m),
						by=c('campground_name','campground_code','lat','lon')) %>%
	mutate(elevation_m=coalesce(elevation_m,inferred_el))

indat %>%
	readr::write_csv(opt$OUTFILE)

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
