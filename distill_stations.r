# /usr/bin/r
#
# Created: 2017.05.16
# Copyright: Steven E. Pav, 2017
# Author: Steven E. Pav <steven@gilgamath.com>
# Comments: Steven E. Pav

suppressMessages(library(docopt))       # we need docopt (>= 0.3) as on CRAN

doc <- "Usage: distill_stations.r [-v] INFILE [OUTFILE]

-v --verbose                     Be more verbose
-h --help                        show this help text"

opt <- docopt(doc)

suppressMessages({
	library(dplyr)
	library(readr)
})

indat <- readr::read_csv(opt$INFILE)

outdat <- indat %>% 
	group_by(STATION) %>%
		summarize(nstats=n()) %>%
	ungroup() %>%
	filter(nstats >= 3) %>%
	select(STATION)

if (is.null(opt$OUTFILE)) {
	outdat %>%
		readr::format_csv() %>%
		show()
} else {
	outdat %>% 
		readr::write_csv(opt$OUTFILE)
}

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
