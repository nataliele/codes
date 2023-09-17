# goal: map campsites along the eclispe pathway
# using: shiny, leaflet
# source: https://www.r-bloggers.com/r-and-gis-working-with-shapefiles/


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
  "tidyr",     # data reshaping package
  "maptools",
  "rgeos"
)


#keeping packages and R up-to-date
update.packages(oldPkgs = pkgs)


#install only packages that's not installed yet
(to_install = pkgs[!pkgs %in% installed.packages()])
if(length(to_install) > 0){
  install.packages(to_install)
}



library(maptools)

#create object to hold the projection
crswgs84=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

#create object
eclipse=readShapePoly("/cloud/project/eclipse/2024eclipse_shapefiles/upath_hi.shp",proj4string=crswgs84,verbose=TRUE)

#explore the type of object
class(eclipse)

#This object has 5 slots - data, polygons, plotOrder,bbox, proj4string
str(eclipse@data)
str(eclipse@polygons)
str(eclipse@bbox)
eclipse@bbox
eclipse@polygons
eclipse@proj4string

#plot the shapefile
plot(eclipse)





#############################################################
library(leaflet)
m <- leaflet() %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addMarkers(lng=-80.07055556, lat=35.43916667, popup="camp")
m  # Print the map
# %>% is the pipe operator


# read in campsite file
camps <- read.csv("/cloud/project/eclipse/fed_campsites.csv"
                          , header=T) 

#clean up dataset: remove unnecessary columns, 
camps_clean <- camps[,5:9]
camps_clean <- unique(camps_clean)
#remove empty/na rows
camps_clean <- camps_clean[rowSums(is.na(camps_clean)) == 0,]
camps_clean <- camps_clean[!(camps_clean$FacilityName=="COTTONSHED PARK (AR)"
                            | camps_clean$FacilityName=="POUND RIVER CAMPGROUND (VA)"
                            | camps_clean$FacilityName=="KANER FLAT CAMPGROUND"),]

test <- leaflet() %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addCircles(data=camps_clean, lng = ~ FacilityLongitude, lat = ~ FacilityLatitude
             , color = "blue"
             , popup = paste("Camp name:", camps_clean$FacilityName, "<br>",
                             "State:", camps_clean$AddressStateCode, "<br>",
                             "Lng:", camps_clean$FacilityLongitude , "<br>",
                             "Lat:", camps_clean$FacilityLatitude ))
test  # Print the map

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



# when subsetting by row values, need to add ',' to get all columns because this is a matrix
camps_no_path <-camps_clean[camps_clean$in_path==0,]
camps_path <-camps_clean[camps_clean$in_path==1,]

#put 2 layers together
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

# export
library(htmlwidgets) 
saveWidget(m, "/cloud/project/eclipse/eclipse.html")
