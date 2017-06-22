# /usr/bin/r
#
# Created: 2017.05.05
# Copyright: Steven E. Pav, 2017
# Author: Steven E. Pav <steven@gilgamath.com>
# Comments: Steven E. Pav

suppressMessages({
	library(dplyr)
	library(tidyr)
	library(tibble)
	library(readr)
	library(knitr)
})

alldat <- readr::read_csv('all.csv',col_types=readr::cols(station_elevation=col_double()))
alldat %>% nrow()
alldat %>% distinct(station_code) %>% nrow()
alldat %>% distinct(station_code) %>% head() %>% kable()

#|station_code |
#|:------------|
#|US1CAMR0032  |
#|US1CAAL0016  |
#|US1CASM0007  |
#|USR0000CBAR  |
#|USC00045915  |
#|US1CAAL0012  |

stat <- 'US1CAMR0032'
id <- paste0(c('GHCND',stat),collapse=':')
library(rnoaa)

options(noaakey='IrHDRKeqNIFxpLZLfQVlYcoQZNQxpqht')
ncdc_stations(stationid = id)
ncdc_datacats(stationid = id)

#$meta
#$meta$totalCount
#[1] 2

#$meta$pageCount
#[1] 25

#$meta$offset
#[1] 1


#$data
           #name   id
#1      Computed COMP
#2 Precipitation PRCP

#attr(,"class")
#[1] "ncdc_datacats"


rains <- ncdc(datasetid='GHCND', stationid=id, datatypeid='PRCP', startdate='2016-01-01', enddate='2016-12-31')

require(knitr)
rains$data %>% kable()

#|date                |datatype |station           | value|fl_m |fl_q |fl_so |fl_t |
#|:-------------------|:--------|:-----------------|-----:|:----|:----|:-----|:----|
#|2016-01-01T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |
#|2016-01-03T00:00:00 |PRCP     |GHCND:US1CAMR0032 |    41|     |     |N     |     |
#|2016-01-04T00:00:00 |PRCP     |GHCND:US1CAMR0032 |    41|     |     |N     |     |
#|2016-01-05T00:00:00 |PRCP     |GHCND:US1CAMR0032 |   549|     |     |N     |     |
#|2016-01-14T00:00:00 |PRCP     |GHCND:US1CAMR0032 |   419|     |     |N     |     |
#|2016-01-16T00:00:00 |PRCP     |GHCND:US1CAMR0032 |   140|     |     |N     |     |
#|2016-01-17T00:00:00 |PRCP     |GHCND:US1CAMR0032 |    56|     |     |N     |     |
#|2016-01-18T00:00:00 |PRCP     |GHCND:US1CAMR0032 |   391|     |     |N     |     |
#|2016-01-24T00:00:00 |PRCP     |GHCND:US1CAMR0032 |    15|     |     |N     |     |
#|2016-01-25T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     8|     |     |N     |     |
#|2016-01-26T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     8|     |     |N     |     |
#|2016-01-28T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |
#|2016-01-30T00:00:00 |PRCP     |GHCND:US1CAMR0032 |    38|     |     |N     |     |
#|2016-02-09T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |
#|2016-02-10T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |
#|2016-02-18T00:00:00 |PRCP     |GHCND:US1CAMR0032 |   211|     |     |N     |     |
#|2016-02-22T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |
#|2016-02-23T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |
#|2016-02-24T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |
#|2016-02-25T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |
#|2016-02-26T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |
#|2016-02-27T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     3|     |     |N     |     |
#|2016-02-29T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |
#|2016-03-01T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |
#|2016-03-02T00:00:00 |PRCP     |GHCND:US1CAMR0032 |     0|     |     |N     |     |

compo <- ncdc(datasetid='GHCND', stationid=id, datatypeid='COMP', startdate='2016-01-01', enddate='2016-12-31')

allo <- ncdc(datasetid='GHCND', stationid=id, startdate='2016-01-01', enddate='2016-12-31', includemetadata=TRUE)

|station_code |
|:------------|
|US1CAMR0032  |
|US1CASM0007  |
|USR0000CBAR  |
|USC00045915  |
|US1CAAL0012  |

id <- 'GHCND:US1CAAL0016'
allo <- ncdc(datasetid='GHCND', stationid=id, startdate='2016-01-01', enddate='2016-12-31', includemetadata=TRUE)

stat <- 'US1CAMR0032'
id <- paste0(c('GHCND',stat),collapse=':')

dly <- ncdc(datasetid='NORMAL_DLY', stationid='GHCND:US1CAMR0032', startdate='2016-01-01', enddate='2016-03-31')
dly <- ncdc(datasetid='NORMAL_DLY', stationid='GHCND:US1CAAL0016', startdate='2016-01-01', enddate='2016-03-31')

foo <- ncdc(datasetid='NORMAL_DLY', datatypeid='dly-tmax-normal', startdate='2016-01-01', enddate='2016-03-31')

out <- ncdc(datasetid='NORMAL_DLY', datatypeid='dly-tmax-normal', startdate = '2010-05-01', enddate = '2010-05-10')
out$data

dly <- ncdc(datasetid='NORMAL_DLY', stationid='GHCND:US1CAAL0016', startdate='2010-01-01', enddate='2010-03-31')
dly <- ncdc(datasetid='NORMAL_DLY', datatypeid='dly-tmax-normal', stationid='GHCND:US1CAAL0016', startdate='2010-01-01', enddate='2010-03-31')


effit <- function(statcode) {
	dly <- ncdc(datasetid='NORMAL_DLY', stationid=paste0('GHCND:',statcode), startdate='2010-01-01', enddate='2010-03-31')
}
require(tidyr)

system.time({
blah <- alldat %>%
	distinct(station_code) %>% 
	group_by(station_code) %>%
		mutate(effy=list(effit(station_code))) %>%
	ungroup() %>%
	unnest()

blah %>% readr::write_csv('wow_data.csv')
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

require(rnoaa)

ghcnd_splitvars(df)


#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
