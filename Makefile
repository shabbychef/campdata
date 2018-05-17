
INTERMED 				= intermediate

.PHONY : help

help:  ## generate this help message
	@grep -h -P '^(([^\s]+\s+)*([^\s]+))\s*:.*?##\s*.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

ghcnd-stations.txt: 
	wget "ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt"

# download the upstream data from uscampgrounds.info# FOLDUP
UPSTREAM_D 			 = uscampgrounds

UPSTREAM_CSV 		 = $(foreach region,West Southwest Midwest Northeast South Canada,$(UPSTREAM_D)/$(region)Camp.csv)

$(UPSTREAM_CSV) : $(UPSTREAM_D)/%.csv : 
	mkdir -p $(UPSTREAM_D)
	wget -O $@ "http://www.uscampgrounds.info/POI/$*.csv"

.PHONY : upstream_csv

upstream_csv : $(UPSTREAM_CSV)  ## download the upstream CSV files of camping info

# assemble them

$(INTERMED) : 
	mkdir -p $@

$(INTERMED)/AllCamp.csv : assembler.r $(UPSTREAM_CSV) | $(INTERMED) 
	r $(filter %.r,$^) --outfile=$@ $(filter %.csv,$^)

.PHONY : intermed_camp

intermed_camp : $(INTERMED)/AllCamp.csv  ## assemble raw camp data files to one dataset


$(INTERMED)/MoreCamp.csv : $(INTERMED)/AllCamp.csv elevation.r | $(INTERMED)
	r $(filter %.r,$^) $(filter %.csv,$^) $@

.PHONY : more_camp

more_camp : $(INTERMED)/MoreCamp.csv  ## get missing elevation data


# UNFOLD




# daily climate data. much easier# FOLDUP
DAILY_D					= daily
TEMP_D 				  = $(DAILY_D)/temperature
PRCP_D 				  = $(DAILY_D)/precipitation


$(DAILY_D)/%.txt : 
	mkdir -p $(basename $@)
	wget -O $@ 'ftp://ftp.ncdc.noaa.gov/pub/data/normals/1981-2010/products/$*.txt'

DAILY_NEEDED 		 = $(TEMP_D)/dly-tavg-normal.txt $(TEMP_D)/dly-tmax-normal.txt $(TEMP_D)/dly-tmin-normal.txt 
DAILY_NEEDED 		+= $(PRCP_D)/dly-prcp-50pctl.txt 

.PHONY: daily_needed

daily_needed : $(DAILY_NEEDED)  ## download the needed daily climate data.

# weeklys 
WEEKLY_D					= weekly

$(WEEKLY_D) :
	mkdir -p $@

$(WEEKLY_D)/% : $(TEMP_D)/% get_weekly.r | $(WEEKLY_D)
	r $(filter %.r,$^) $(filter-out %.r,$^) $@

$(WEEKLY_D)/% : $(PRCP_D)/% get_weekly.r | $(WEEKLY_D)
	r $(filter %.r,$^) $(filter-out %.r,$^) $@

WEEKLY_NEEDED 		 = $(WEEKLY_D)/dly-tavg-normal.txt $(WEEKLY_D)/dly-tmax-normal.txt $(WEEKLY_D)/dly-tmin-normal.txt 
WEEKLY_NEEDED 		+= $(WEEKLY_D)/dly-prcp-50pctl.txt 

.PHONY : weekly_needed

weekly_needed : $(WEEKLY_NEEDED)  ## convert daily to weekly files
# UNFOLD

#for vim modeline: (do not edit)
# vim:ts=2:sw=2:tw=79:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:tags=.tags;:syn=make:ft=make:ai:si:cin:nu:fo=croqt:cino=p0t0c5(0:
