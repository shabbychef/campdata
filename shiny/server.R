# /usr/bin/r
#
# shiny comp page, server
#
# Created: 2015.09.10
# Copyright: Steven E. Pav, 2015
# Author: Steven E. Pav <steven@corecast.io>
# Comments: Steven E. Pav


suppressMessages({
	library(shiny)
	library(ggplot2)
	library(dplyr)
	library(geosphere)
	library(magrittr)
	library(ggmap)
})

.applylink <- function(title,url) {
	as.character(a(title,href=url,target="_blank"))
}
applylink <- function(title,url) {
	as.character(mapply(.applylink,title,url))
}

.logical_it <- function(x) {
	as.logical(toupper(x))
}

MPF <<- 0.3048   # meters per foot
KMPMi <<- 1.60934   # km per mile

# Define server logic 
shinyServer(function(input, output, session) {
	#cat('server!\n',file='/tmp/shiny.err')
	searched <- reactiveValues(text=c(),
														 lat=c(),
														 lon=c())

	observeEvent(input$do_lookup,
					{
						response <- ggmap::geocode(input$location_lookup)
						searched$text <- input$location_lookup
						searched$lat <- response$lat
						searched$lon <- response$lon
						updateNumericInput(session,'sel_lat',value=response$lat)
						updateNumericInput(session,'sel_lon',value=response$lon)
					})

	selunits <- reactiveValues(system='metric')
	observeEvent(input$sel_units,
					{
						old_units <- selunits$system
						new_units <- input$sel_units
						if (old_units != new_units) {
							old_elevation <- input$sel_elevation
							old_dist <- input$sel_dist
							if (new_units=='metric') {
								new_elevation <- old_elevation * MPF
								updateSliderInput(session,'sel_elevation',
																	label="Elevation Range (m)",
																	min=0,max=4000,value=round(new_elevation),step=1)

								new_dist <- old_dist * KMPMi 
								updateSliderInput(session,'sel_dist',
																	label="Distance to point (km)",
																	min=0,max=1500,value=round(new_dist),step=1)
							} else {
								new_elevation <- old_elevation / MPF
								updateSliderInput(session,'sel_elevation',
																	label="Elevation Range (ft)",
																	min=0,max=round(4000 / MPF),value=round(new_elevation),step=1)

								new_dist <- old_dist / KMPMi 
								updateSliderInput(session,'sel_dist',
																	label="Distance to point (mi)",
																	min=0,max=round(1500 / KMPMi),value=round(new_dist),step=1)
							}
						}
						selunits$system <- new_units
					})

	just_load <- reactive({
		indat <- readr::read_csv('../intermediate/AllCamp.csv') 
		indat
	})

	filtered_data <- reactive({
		indat <- just_load()
		if (input$sel_units=='metric') {
			elrange <- input$sel_elevation
		} else {
			elrange <- input$sel_elevation * MPF
		}

		otdat <- indat %>%
			filter((length(input$sel_type)==0) | (type %in% input$sel_type),
						 (length(input$sel_toilets)==0) | (toilets %in% input$sel_toilets),
						 (length(input$sel_showers)==0) | (showers %in% .logical_it(input$sel_showers)),
						 (length(input$sel_drinking_water)==0) | (drinking_water %in% .logical_it(input$sel_drinking_water)),
						 (length(input$sel_reservations)==0) | (reservations %in% .logical_it(input$sel_reservations)),
						 (!is.na(num_campsite) & (num_campsite >= min(input$sel_num_campsite) & num_campsite <= max(input$sel_num_campsite)) | (is.na(num_campsite))),
						 (!is.na(elevation_m) & (elevation_m >= min(elrange)) & (elevation_m <= max(elrange))) | (is.na(elevation_m)))
		otdat
	})

	dist_data <- reactive({
		srch_lonlat <- c(input$sel_lon,input$sel_lat)

		if (input$sel_units=='metric') {
			dirange <- input$sel_dist
		} else {
			dirange <- input$sel_dist * KMPMi
		}

		otdat <- filtered_data() %>%
			mutate(sdist = round(1e-3 * geosphere::distGeo(srch_lonlat,matrix(c(lon,lat),ncol=2) ),digits=2)) %>%
			filter(sdist >= min(dirange),sdist <= max(dirange)) %>%
			arrange(sdist) 
		otdat 
	})

	# table of comparables #FOLDUP
	output$camp_table <- DT::renderDataTable({
		otdat <- dist_data()

		showdat <- otdat %>%
			select(campground_name,sdist,
						 type,lat,lon,
						 nearest_town,state,
						 elevation_m,
						 num_campsite,
						 drinking_water,toilets,showers,reservations)  %>%
		rename(`campground`=campground_name,
					 `nearest town`=nearest_town,
					 `num campsites`=num_campsite)

		if (selunits$system=='imperial') {
			showdat %<>%
				mutate(elevation_m=elevation_m / MPF,
							 sdist=sdist / KMPMi) %>%
				mutate(elevation_m=round(elevation_m),
							 sdist=round(sdist,1)) %>%
				rename(`dist to point, mi`=sdist,
							 `elevation ft`=elevation_m)
		} else {
			showdat %<>%
				mutate(elevation_m=round(elevation_m),
							 sdist=round(sdist,1)) %>%
				rename(`dist to point, km`=sdist,
							 `elevation m`=elevation_m)
		}

		# for this javascript shiznit, recall that javascript starts
		# counting at zero!
		#
		# cf 
		# col rendering: http://rstudio.github.io/DT/options.html
		# https://github.com/jcheng5/shiny-jsdemo/blob/master/ui.r
		DT::datatable(showdat,
									caption='Matching campgrounds',
									escape=FALSE,
									rownames=FALSE,
									options=list(order=list(list(1,'asc')),
															 paging=TRUE,
															 pageLength=15))
	},
	server=TRUE)#UNFOLD

	setBookmarkExclude(c('bookmark'))
	observeEvent(input$bookmark,{
								 session$doBookmark()
	})

})

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
