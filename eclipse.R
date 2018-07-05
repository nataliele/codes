# goal: map campsites along the eclispe pathway
# using: shiny, leaflet
# source: https://www.r-bloggers.com/r-and-gis-working-with-shapefiles/

#keeping packages and R up-to-date
update.packages(oldPkgs = pkgs)

#packages required
pkgs = c(
  "sp",       # spatial data classes and functions
  "ggmap",    # maps the ggplot2 way
  "tmap",     # powerful and flexible mapping package
  "leaflet",  # interactive maps via the JavaScript library of the same name
  "mapview",  # a quick way to create interactive maps (depends on leaflet)
  "shiny",    # for converting your maps into online applications
  "OpenStreetMap", # for downloading OpenStreetMap tiles 
  "rasterVis",# raster visualisation (depends on the raster package)
  "dplyr",    # data manipulation package
  "tidyr"     # data reshaping package
)

#install only packages that's not installed yet
(to_install = pkgs[!pkgs %in% installed.packages()])
if(length(to_install) > 0){
  install.packages(to_install)
}

library(maptools)

#create object to hold the projection
crswgs84=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

#create object
eclipse=readShapePoly("[your_file_path]",proj4string=crswgs84,verbose=TRUE)

#explore the type of object
class(eclipse)

#This object has 5 slots – data, polygons, plotOrder,bbox, proj4string
str(eclipse@data)
str(eclipse@polygons)
str(eclipse@bbox)
eclipse@bbox
eclipse@polygons
eclipse@proj4string

#plot the shapefile
plot(eclipse)

camps <- read.csv("[your_file_path]", header=T) 

#clean up dataset: remove unecessary columns, 
camps_clean <- camps[,5:9]
camps_clean <- unique(camps_clean)
#remove empty/na rows
camps_clean <- camps_clean[rowSums(is.na(camps_clean)) == 0,]
camps_clean <- camps_clean[!(camps_clean$FacilityName=="COTTONSHED PARK (AR)"
                            | camps_clean$FacilityName=="POUND RIVER CAMPGROUND (VA)"
                            | camps_clean$FacilityName=="KANER FLAT CAMPGROUND"),]


#check if the polygon contains a location
library(rgeos)

#loop to check if the eclipse polygon contains the location of a camp
#get size/dimensions of table camps_clean
count=dim(camps_clean)
camps_clean$in_path <-0

for (i in 1:count[1]){
  p <- SpatialPoints(list(camps_clean$FacilityLongitude[i],camps_clean$FacilityLatitude[i]), proj4string=crswgs84)
  camps_clean$in_path[i] <- gContains(eclipse,p)
}
#if gcontains is true then the location is in the polygon

# subsetting the table into 2 groups: one on the path and one not on the path
camps_no_path <-camps_clean[camps_clean$in_path==0,]
camps_path <-camps_clean[camps_clean$in_path==1,]

library(leaflet)

#put 4 layers together
m <- leaflet() %>%
  # addTiles() %>% 
  # cannot use just addtiles because of a bug when exporting, resulted in no base map
  addProviderTiles("OpenStreetMap.Mapnik") %>%
  addPolygons(data = eclipse, color="purple") %>% 
  addCircles(data=camps_no_path, lng = ~ FacilityLongitude, lat = ~ FacilityLatitude
                            , color = "blue"
                            , popup = paste("Camp name:", camps_no_path$FacilityName, "<br>",
                                            "State:", camps_no_path$AddressStateCode, "<br>",
                                            "Lng:", camps_no_path$FacilityLongitude , "<br>",
                                            "Lat:", camps_no_path$FacilityLatitude )) %>% 
  addCircles(data=camps_path, lng = ~ FacilityLongitude, lat = ~ FacilityLatitude
                           , color = "red"
                           , popup = paste("Camp name:", camps_path$FacilityName, "<br>",
                                           "State:", camps_path$AddressStateCode, "<br>",
                                           "Lng:", camps_path$FacilityLongitude , "<br>",
                                           "Lat:", camps_path$FacilityLatitude ))
m

# export to html
library(htmlwidgets) 
saveWidget(m, "eclipse.html")