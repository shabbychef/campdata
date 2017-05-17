# /usr/bin/r
#
# Created: 2017.05.14
# Copyright: Steven E. Pav, 2017
# Author: Steven E. Pav <steven@gilgamath.com>
# Comments: Steven E. Pav

suppressMessages(library(docopt))       # we need docopt (>= 0.3) as on CRAN

doc <- "Usage: getcaps.r [-v] INFILE [OUTFILE]

-v --verbose                     Be more verbose
-h --help                        show this help text"

opt <- docopt(doc)
#opt <- docopt(doc,arg='noaa/ghcnd_all/ACW00011604.dly')

suppressMessages({
	library(readr)
	library(dplyr)
})

read_dly <- function(fname) {
	require(readr)

# widths anf variable names
  vars <- c("id","year","month","element",as.character(outer(c("VALUE","MFLAG","QFLAG","SFLAG"),1:31,FUN="paste0")))
	wids <- readr::fwf_widths(c(11,4,2,4,rep(c(5,1,1,1), 31)),col_names=vars)

# column types; most are char, but force these to be int:
	col_t <- readr::cols(
		year = col_integer(), 
		VALUE1 = col_integer(), VALUE2 = col_integer(), VALUE3 = col_integer(), VALUE4 = col_integer(),
		VALUE5 = col_integer(), VALUE6 = col_integer(), VALUE7 = col_integer(), VALUE8 = col_integer(),
		VALUE9 = col_integer(), VALUE10 = col_integer(), VALUE11 = col_integer(), VALUE12 = col_integer(),
		VALUE13 = col_integer(), VALUE14 = col_integer(), VALUE15 = col_integer(), VALUE16 = col_integer(),
		VALUE17 = col_integer(), VALUE18 = col_integer(), VALUE19 = col_integer(), VALUE20 = col_integer(),
		VALUE21 = col_integer(), VALUE22 = col_integer(), VALUE23 = col_integer(), VALUE24 = col_integer(),
		VALUE25 = col_integer(), VALUE26 = col_integer(), VALUE27 = col_integer(), VALUE28 = col_integer(),
		VALUE29 = col_integer(), VALUE30 = col_integer(), VALUE31 = col_integer(),
		.default = col_character())
	
# read it
  df <- readr::read_fwf(fname, wids, na=c("-9999"), col_types=col_t)
}

indata <- read_dly(opt$INFILE) 
outdat <- indata %>%
		filter(year >= 2014) %>% 
		group_by(element) %>%
			summarize(nomo=n(),
								yrspan=max(year)-min(year)) %>%
		ungroup()
			
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
