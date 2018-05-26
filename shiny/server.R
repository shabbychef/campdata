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
	library(urltools)
	library(stringr)
	library(lubridate)
})

.applylink <- function(title,url) {
	as.character(a(title,href=url,target="_blank"))
}
applylink <- function(title,url) {
	as.character(mapply(.applylink,title,url))
}
.search_link <- function(campground,city,state) {
	require(stringr)
	require(urltools)
	searchterm <- url_encode(paste(campground,city,state))
	url <- stringr::str_interp('https://www.google.com/search?q=${searchterm}&ie=utf-8&oe=utf-8')
	.applylink(title=campground,url=url)
}
search_link <- function(campground,city,state) {
	as.character(mapply(.search_link,campground,city,state))
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
						maxdist_km <- 800
						minelev_m <- -100
						maxelev_m <- 4000

						old_units <- selunits$system
						new_units <- input$sel_units
						if (old_units != new_units) {
							old_elevation <- input$sel_elevation
							old_dist <- input$sel_dist
							if (new_units=='metric') {
								new_elevation <- old_elevation * MPF
								updateSliderInput(session,'sel_elevation',
																	label="Elevation Range (m)",
																	min=minelev_m,max=maxelev_m,value=round(new_elevation),step=1)

								new_dist <- old_dist * KMPMi 
								updateSliderInput(session,'sel_dist',
																	label="Distance to point (km)",
																	min=0,max=maxdist_km,value=round(new_dist),step=1)
							} else {
								new_elevation <- old_elevation / MPF
								updateSliderInput(session,'sel_elevation',
																	label="Elevation Range (ft)",
																	min=round(minelev_m / MPF),max=round(maxelev_m / MPF),value=round(new_elevation),step=1)

								new_dist <- old_dist / KMPMi 
								updateSliderInput(session,'sel_dist',
																	label="Distance to point (mi)",
																	min=0,max=round(maxdist_km / KMPMi),value=round(new_dist),step=1)
							}
						}
						selunits$system <- new_units
					})

	# in km
	maximum_radius <- reactive({
		units <- input$sel_units
		if (units=='metric') {
			myrad <- input$sel_dist
		} else {
			myrad <- input$sel_dist * KMPMi
		}
		max(myrad)
	})
	get_zoom_level <- reactive({
		# in km
		myrad <- maximum_radius()
		zl <- dplyr::case_when(myrad < 100 ~ 9L,
														 myrad < 175 ~ 8L,
														 myrad < 250 ~ 7L,
														 myrad < 500 ~ 6L,
														 TRUE ~ 5L)
		zl 
	})

	just_load <- reactive({
		indat <- readr::read_csv('../intermediate/MoreCamp.csv') 
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

		if (input$sel_restrict_date) {
			weeknum <- lubridate::isoweek(input$sel_date)
			# get rid of things which are definitely closed.
			otdat %<>%
				filter((is.na(opening_week) | is.na(closing_week)) |
							 ((opening_week <= weeknum) & (weeknum <= closing_week)) |   # closed in winter, which makes sense
							 ((closing_week < opening_week) & ((opening_week <= weeknum) | (weeknum <= closing_week))))
		}

		otdat
	})

	search_data <- reactive({
		srch_df <- data_frame(lon=input$sel_lon,
													lat=input$sel_lat,
													location=coalesce(input$location_lookup,''))
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


	map_data <- reactive({
		zl <- input$sel_zoom
		zl <- get_zoom_level()
		thedata <- ggmap::get_map(location=c(lon=input$sel_lon,lat=input$sel_lat),zoom=zl,
															maptype='roadmap',source='google',force=TRUE)
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
						 drinking_water,toilets,showers,reservations,dates_open)  %>%
		rename(`campground`=campground_name,
					 `nearest town`=nearest_town,
					 `num campsites`=num_campsite,
					 `dates open`=dates_open)

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

		showdat %<>%
			mutate(campground=search_link(campground,`nearest town`,state))

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

	output$camps_map <- renderPlot({
		mapd <- map_data()
		otdat <- dist_data()
		srch_df <- search_data()

		ph <- mapd %>% 
			ggmap() +
			geom_point(aes(x=lon,y=lat,size=num_campsite,label=campground_name),data=otdat,alpha=0.5) +
			geom_text(aes(x=lon,y=lat,label=campground_name),data=otdat,color='red',alpha=0.8) +
			geom_point(aes(x=lon,y=lat,label=location),data=srch_df,shape=3,color='blue',size=5,alpha=0.8) +
			geom_text(aes(x=lon,y=lat,label=location),data=srch_df,hjust='left',vjust='bottom',color='blue',size=7,alpha=0.8) 

		ph
	})

	setBookmarkExclude(c('bookmark'))
	observeEvent(input$bookmark,{
								 session$doBookmark()
	})

})

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
