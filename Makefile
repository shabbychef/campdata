

GHCND_ALL 			= ghcnd_all.tar.gz  
NOAA_D 					= noaa
OK_STATION_FILE 			= $(NOAA_D)/ok_stations.csv 

.PHONY : help

help:  ## generate this help message
	@grep -h -P '^(([^\s]+\s+)*([^\s]+))\s*:.*?##\s*.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

ghcnd-stations.txt: 
	wget "ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt"


all.csv : converter.r $(OK_STATION_FILE) CanadaCamp.csv  SouthwestCamp.csv  WestCamp.csv ghcnd-stations.txt ## conver raw camp data files to one dataset
	r $(filter %.r,$^) --station_file=$(filter %.txt,$^) \
		--ok_station_list=$(firstword $(filter %.csv,$^)) \
		--outfile=$@ $(wordlist 2,100,$(filter %.csv,$^))

--ok_station_list=AFILE          Give the csv of the list of OK STATIONs in the STATIONFILE. [default: ok_stations.csv]

# get the upstream data.
# see ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt

.PHONY : ghcnd_all


.PRECIOUS : $(GHCND_ALL)

ghcnd_all : $(GHCND_ALL) ## download the huge ghcnd data dump

$(GHCND_ALL) : 
	wget -O $@ 'ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd_all.tar.gz'

$(NOAA_D) :
	mkdir -p $@

$(NOAA_D)/ghcnd_all : $(GHCND_ALL) | $(NOAA_D)
	tar -C $(NOAA_D) -zxvf $<

$(NOAA_D)/ghcnd_caps :
	mkdir -p $@

$(NOAA_D)/ghcnd_nice :
	mkdir -p $@

# this is about 200 of them?
#ALL_DLY 			:= $(wildcard $(NOAA_D)/ghcnd_all/A*10.dly)
# this is all :
ALL_DLY 			:= $(wildcard $(NOAA_D)/ghcnd_all/*.dly)
#SUB_DLY 			:= $(wildcard $(NOAA_D)/ghcnd_all/*.dly)
#ALL_DLY 			 = $(wordlist 1,100,$(SUB_DLY))
##ALL_DLY 				= $(shell ls $(NOAA_D)/ghcnd_all | head)
ALL_CAPS				= $(subst ghcnd_all,ghcnd_caps,$(patsubst %.dly,%_cap.csv,$(ALL_DLY)))

# ALL CAPS# FOLDUP
.PHONY : all_caps

all_caps : $(ALL_CAPS)  ## make weather station capabilities files.

$(NOAA_D)/ghcnd_caps/%_cap.csv : $(NOAA_D)/ghcnd_all/%.dly getcaps.r | $(NOAA_D)/ghcnd_caps
	r $(filter %.r,$^) $(filter %.dly,$^) $@ 

.PHONY : total_caps

total_caps : $(NOAA_D)/total_cap.csv  ## gather all capabilities files.

$(NOAA_D)/total_cap.csv : 
	echo "STATION,element,nomo,yrspan" > $@
	find $(NOAA_D)/ghcnd_caps -name '*_cap.csv' -type f -exec grep -H -P '(PRCP|TMAX|TMIN),(4[01]|3[56789]),3' {} \; | \
		perl -pe 's{^.+([A-Z].{10,10})_cap.csv:}{$$1,};' >> $@
# UNFOLD

# ALL NICE# FOLDUP
ALL_NICE				= $(subst ghcnd_all,ghcnd_nice,$(patsubst %.dly,%_nice.csv,$(ALL_DLY)))

.PHONY : all_nice

all_nice : $(ALL_NICE)  ## make weather station props nice files.

$(NOAA_D)/ghcnd_nice/%_nice.csv : $(NOAA_D)/ghcnd_all/%.dly prop_nice.r | $(NOAA_D)/ghcnd_nice
	r $(filter %.r,$^) $(filter %.dly,$^) $@ 

.PHONY : total_nice

total_nice : $(NOAA_D)/total_nice.csv  ## gather all nice props files.

$(NOAA_D)/total_nice.csv : 
	csvstack $(NOAA_D)/ghcnd_nice/*nice.csv > $@
# UNFOLD

.PHONY : station_list

station_list : $(OK_STATION_FILE) ## gather all acceptable stations in a CSV 'list'.


$(OK_STATION_FILE) : $(NOAA_D)/total_cap.csv distill_stations.r 
	r $(filter %.r,$^) $(filter %.csv,$^) $@ 


