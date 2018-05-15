# /usr/bin/r
#
# shiny comp page, UI
#
# Created: 2015.09.10
# Copyright: Steven E. Pav, 2015
# Author: Steven E. Pav <steven@corecast.io>
# Comments: Steven E. Pav

suppressMessages({
	library(shiny)
	library(shinyAce)
	library(shinythemes)
	library(readr)
	library(DT)
	library(forcats)
	library(dplyr)
	library(geosphere)
	library(ggmap)
})


indat <- readr::read_csv('../all.csv')

types <- list(national=c('National Park'='NP',
												 'National Monument'='NM',
												 'Canadian National Park'='CNP'),
							forest=c('National Forest'='NF'),
							managed=c('Bureau of Land Management'='BLM',
												'US Fish and Wildlife'='USFW',
												'Bureau of Reclamation'='BOR'),
							etc=c('US Corps of Engineers'='COE','Tennessee Valley Authority'='TVA'),
							state=c('State Park'='SP','Canadian Provincial Park'='PP',
											'State Rec. Area'='SRA','State Preserve'='SPR',
											'State Beach'='SB'),
							state_forest=c('State Forest'='SF',
														 'State Fish and Wildlife'='SFW'),
							military=c('Military only'='ML'),
							other=c('County/City/Regional Park'='CP',
											'Authority'='AUTH',
											'Utility'='UTIL',
											'Native American Reservation'='RES',
											'Unknown'='UNKN'))

# Define UI for ...
shinyUI(
	fluidPage(theme=shinytheme("spacelab"),#FOLDUP
		# for this, see: http://stackoverflow.com/a/22886762/164611
		# Application title
		tags$head(
					# load accounting js
					#tags$script(src='js/accounting.js'),
					tags$script(src='test.js'),
					# points for style:
					tags$style(".table .alignRight {color: black; text-align:right;}"),
					tags$link(rel="stylesheet", type="text/css", href="style.css")
		),
		titlePanel("Happy CampR"),
		# tags$img(id = "logoimg", src = "logo.png", width = "200px"),
		sidebarLayout(#FOLDUP
			position="left",
		sidebarPanel(#FOLDUP
			width=2,
			h3('Parameters'),
			textInput("location_lookup","Lookup Location:",value='',placeholder='Monument Valley'),
			actionButton("do_lookup",label='go'),
			numericInput("sel_lat","Latitude",value=37.7749,min=0,max=90,step=0.0001),
			numericInput("sel_lon","Longitude",value=-122.4194,min=-180,max=180,step=0.0001),
			selectInput("sel_type","Campground Type:",choices=types,selected='National Park',multiple=TRUE),
			selectInput("sel_toilets","Toilets:",choices=c('flush','vault','pit','flush_and_vault','none',NA),
									selected='flush',multiple=TRUE),
			selectInput("sel_showers","Showers:",choices=c('true','false','unknown'),
									selected='true',multiple=TRUE),
			selectInput("sel_drinking_water","Drinking Water:",choices=c('true','false','unknown'),
									selected='true',multiple=TRUE),
			selectInput("sel_reservations","Accepts Reservations:",choices=c('true','false','unknown'),
									selected='true',multiple=TRUE),
			hr(),
			sliderInput("sel_elevation","Elevation Range",sep=',',post='m',min=0,max=4000,value=c(0,1800)),
			sliderInput("sel_num_campsite","Num Campsite Range",sep=',',post=' sites',min=0,max=1000,value=c(0,250)),
			hr(),
			helpText('data scraped from the web'),
			bookmarkButton('bookmark',title='bookmark page'),
			hr()
			),#UNFOLD
	mainPanel(#FOLDUP
		width=9,
		tabsetPanel(
			tabPanel('data',#FOLDUP
					DT::dataTableOutput('camp_table')
					)#UNFOLD
				) # tabSetPanel
			)  # mainPanel#UNFOLD
		) # sidebarLayout#UNFOLD
	)  # fluidPage#UNFOLD
)  # shinyUI


#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
