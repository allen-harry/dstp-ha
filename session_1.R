library(osmextract)
library(tidyverse)
library(sf)
library(stats19)
library(pct)

# Getting features
west_yorkshire <- osmextract::oe_get(
    place = "West Yorkshire",
    extra_tags = c("maxspeed", "lit", "cycleway"),
    query = "SELECT * FROM lines WHERE highway IN ('cycleway', 'path')"
)

plot(sf::st_geometry(west_yorkshire))

# Amenity features
west_yorkshire_am <- osmextract::oe_get(
    layer = "points",
    place = "West Yorkshire",
    extra_tags = c("amenity")
)

plot(sf::st_geometry(west_yorkshire_am))

# Converting data to table
amenity_table <- west_yorkshire_am$amenity %>%
    table()

# Casulty data
collisions <- stats19::get_stats19(year = 2020,
                                   type = "collision")
casualties <- stats19::get_stats19(year = 2020,
                                  type = "cas")
vehicles <- stats19::get_stats19(year = 2020,
                                  type = "veh")

# Origin-destination data
leeds_lines <- pct::get_pct_lines(region = "west-yorkshire")

# Reading shape files
url = "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Lower_layer_Super_Output_Areas_December_2021_Boundaries_EW_BFE_V10/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"
lsoa_boundaries = sf::st_read(url)

# Cleaning data
clean_collisions <- collisions %>%
    dplyr::filter(!is.na(location_easting_osgr, location_northing_osgr)) %>%
    sf::st_as_sf(coords = c("location_easting_osgr", "location_northing_osgr"), crs = 27700) %>%
    dplyr::select(accident_index, date, speed_limit, accident_severity)

# Exercise 5.1 - Downloading 2019 data
col_2019 <- stats19::get_stats19(year = 2019, type = "collision")
cas_2019 <- stats19::get_stats19(year = 2019, type = "cas")
veh_2019 <- stats19::get_stats19(year = 2019, type = "veh")

# Exploring data
 dplyr::glimpse(col_2019)

# Basic plotting
plot_data <- col_2019 %>%
    dplyr::group_by(accident_severity) %>%
    dplyr::summarise(total = n())

p <- ggplot(data = plot_data, aes(x = accident_severity,
                                  y = total))+
        geom_col()

plot(p)