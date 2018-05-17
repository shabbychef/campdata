# /usr/bin/r
#
# Created: 2017.06.21
# Copyright: Steven E. Pav, 2017
# Author: Steven E. Pav <steven@gilgamath.com>
# Comments: Steven E. Pav

suppressMessages(library(docopt))       # we need docopt (>= 0.3) as on CRAN

doc <- "Usage: best_nice.r [-v] [--station_file <STATIONFILE>] INFILE [OUTFILE]

--station_file=STATIONFILE       Give the station file to lookup weather stations. [default: ghcnd-stations.txt]
-v --verbose                     Be more verbose
-h --help                        show this help text"

opt <- docopt(doc)
#opt <- docopt(doc,args='noaa/total_nice.csv')

suppressMessages({
	library(readr)
	library(tidyr)
	library(dplyr)
})

nice <- readr::read_csv(opt$INFILE) %>%
		filter(mu_ok >= 0.001)

stations <- readr::read_fwf(opt$station_file,
														col_positions=readr::fwf_widths(c(12,9,9,7,3,31,4,4,4)))
colnames(stations) <- c('station','lat','lon','elevation','state','location_name','GSN_flag','HCN_flag','WMO_ID')

outdat <- nice %>%
	left_join(stations,by=c('station'='station')) %>%
	arrange(desc(mu_ok))

if (is.null(opt$OUTFILE)) {
	outdat %>%
		format_csv() %>%
		show()
} else {
	outdat %>% 
		write_csv(opt$OUTFILE)
}

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
