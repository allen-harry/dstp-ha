library(tidyverse)
library(flowmapblue)
library(sf)

# Load bike docking station locations with spatial geometry
stations = read_sf("https://github.com/itsleeds/tds/releases/download/2025/p3-london-bike_docking_stations.geojson")
# Load trip data as regular CSV (no spatial data, but contains origin/destination IDs)
bike_trips = read.csv("https://github.com/itsleeds/tds/releases/download/2025/p3-london-bike_trips.csv")

# Cleaning station data
location_data <- stations %>% 
  sf::st_transform(crs = 4326) %>% 
  sf::st_coordinates() %>% 
  as.data.frame() %>% 
  dplyr::mutate(id = stations$station_id) %>% 
  dplyr::rename(lon = X,
                lat = Y)

# Getting bike data ready
trips <- bike_trips %>% 
  dplyr::select(-stop_time) %>% 
  dplyr::arrange(start_time) %>% 
  dplyr::rename(origion = start_station_id,
                dest = end_station_id,
                time = start_time) %>% 
  dplyr::mutate(time = as.POSIXct(time)) %>% 
  dplyr::group_by(origion, dest, time) %>% 
  summarise(count = n(), .groups = "drop")

# Creating flow map
flowmap <- flowmapblue::flowmapblue(locations = location_data,
                                    flows = trips,
                                    animation = TRUE,
                                    clustering = TRUE)

flowmap