# /usr/bin/r
#
# convert daily noaa file to weekly csv
#
# Created: 2018.05.15
# Copyright: Steven E. Pav, 2018
# Author: Steven E. Pav <steven@gilgamath.com>
# Comments: Steven E. Pav

suppressMessages(library(docopt))       # we need docopt (>= 0.3) as on CRAN

doc <- "Usage: get_weekly.r [-v] INFILE [OUTFILE]

-v --verbose                     Be more verbose
-h --help                        show this help text"

opt <- docopt(doc)

suppressMessages({
	library(dplyr)
	library(readr)
	library(tidyr)
	library(lubridate)
})

read_dly <- function(fname) {
# these are for climate files, different than normal noaa weather data
	require(readr)

# widths and variable names
  vars <- c("id","month","dummy",as.character(outer(c("VALUE","FLAG"),1:31,FUN="paste0")))
	wids <- readr::fwf_widths(c(11,3,3,rep(c(6,1),31)),col_names=vars)

# column types; most are char, but force these to be int:
	col_t <- readr::cols(
		month = col_integer(), 
		dummy = col_character(),
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
  df <- readr::read_fwf(fname, wids, na=c("-9999"), col_types=col_t) %>%
		select(-dummy)
}

mydf <- read_dly(opt$INFILE) 


fooz <- mydf %>%
	select(id,month,matches('^VALUE')) %>%
	tidyr::gather(key=daynum,value=value,matches('^VALUE')) %>%
	mutate(day=as.integer(as.numeric(gsub('^VALUE','',daynum)))) %>%
	mutate(date=paste0('2009-',month,'-',day)) %>%
	mutate(iweek=lubridate::isoweek(lubridate::ymd(date))) %>%
	select(id,iweek,value) %>%
	group_by(id,iweek) %>%
		summarize(avg_value=mean(value),
							nsamp=n()) %>%
	ungroup() %>%
	filter(nsamp >= 4) %>% select(-nsamp) %>%
	mutate(avg_value=round(avg_value))

if (is.null(opt$OUTFILE)) {
	cat(format_csv(fooz))
} else {
	fooz %>%
		readr::write_csv(opt$OUTFILE)
}

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
