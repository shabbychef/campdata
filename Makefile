

.PHONY : help

help:  ## generate this help message
	@grep -h -P '^(([^\s]+\s+)*([^\s]+))\s*:.*?##\s*.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

ghcnd-stations.txt: 
	wget "ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt"


all.csv : converter.r CanadaCamp.csv  SouthwestCamp.csv  WestCamp.csv ghcnd-stations.txt ## conver raw camp data files to one dataset
	r $(filter %.r,$^) --station_file=$(filter %.txt,$^) --outfile=$@ $(filter %.csv,$^)

