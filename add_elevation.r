# /usr/bin/r
#
# bind (lookup) elevation and camp data together.
#
# Created: 2018.05.17
# Copyright: Steven E. Pav, 2018
# Author: Steven E. Pav <steven@gilgamath.com>
# Comments: Steven E. Pav

suppressMessages(library(docopt))       # we need docopt (>= 0.3) as on CRAN

doc <- "Usage: add_elevation.r [-v] [-e <ELEVATION_CSV>] INFILE OUTFILE

-e ELEVATION_CSV --elevation ELEVATION_CSV   Give the name of the elevation csv [default: intermediate/elevations.csv]
-v --verbose                                 Be more verbose
-h --help                                    show this help text"

opt <- docopt(doc)

suppressMessages({
	library(readr)
	library(dplyr)
	library(tidyr)
})

# load the infile
indat <- readr::read_csv(opt$INFILE) 

elev <- readr::read_csv(opt$elevation)

indat %<>%
	left_join(elev %>% distinct(lat,lon,.keep_all=TRUE),by=c('lat','lon')) %>%
	mutate(elevation_m=coalesce(elevation_m,lookup_elevation_m)) %>%
	select(-lookup_elevation_m) %>%
	arrange(lat,lon)

indat %>% readr::write_csv(opt$OUTFILE)


#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
