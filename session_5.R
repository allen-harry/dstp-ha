library(sf)
library(tidyverse)
library(stplanr)
library(dodgr)
library(opentripplanner)
library(tmap)
library(osmextract)
library(lwgeom)
tmap_mode("view")

## Connecting to the otp
otpcon = otp_connect(
  hostname = "otp.robinlovelace.net",
  ssl = TRUE,
  port = 443,
  router = "west-yorkshire"
)

## Basic routing
# Create a simple walking route from ITS Leeds to Leeds Railway Station
from = stplanr::geo_code("Institute for Transport Studies, Leeds")
to = stplanr::geo_code("Leeds Railway Station")

route_walk = otp_plan(
  otpcon = otpcon,
  fromPlace = from, # c(-1.555, 53.810), # Longitude, Latitude
  toPlace = to, # c(-1.54710, 53.79519),
  mode = "WALK"
)
qtm(route_walk)

## Multi-modal routing
# Public transport route
route_transit = otp_plan(
  otpcon = otpcon,
  fromPlace = c(-1.55555, 53.81005),
  toPlace = c(-1.54710, 53.79519),
  mode = c("WALK", "TRANSIT")
)

qtm(route_transit)

# Cycling with public transport
route_bike_transit = otp_plan(
  otpcon = otpcon,
  fromPlace = c(-1.55555, 53.81005),
  toPlace = c(-1.54710, 53.79519),
  mode = c("BICYCLE", "TRANSIT")
)

qtm(route_bike_transit)

## Loading OD data
# Load desire lines data
desire_lines_raw = read_sf("https://github.com/ITSLeeds/TDS/releases/download/22/NTEM_flow.geojson")
desire_lines = desire_lines_raw |>
  select(from, to, all, walk, drive, cycle)

# Load zone centroids
centroids = read_sf("https://github.com/ITSLeeds/TDS/releases/download/22/NTEM_cents.geojson")

# Filter for top 5 desire lines by total trips
desire_top = desire_lines |>
  slice_max(order_by = all, n = 5)

## Visualising desire lines
tm_shape(desire_lines) +
  tm_lines(
    col = "all",
    lwd = "all",
    lwd.scale = tm_scale_continuous(values.scale = 10),
    col.scale = tm_scale_continuous(values = "-viridis")
  ) +
  tm_shape(centroids) +
  tm_dots(fill = "red", size = 0.5)

# Extract start and end points
fromPlace = sf::st_sf(
  data.frame(id = desire_top$from),
  geometry = lwgeom::st_startpoint(desire_top)
)
toPlace = sf::st_sf(
  data.frame(id = desire_top$to),
  geometry = lwgeom::st_endpoint(desire_top)
)

## Calculating routes
# Calculate driving routes for top desire lines
routes_drive_top = otp_plan(
  otpcon = otpcon,
  fromPlace = fromPlace,
  toPlace = toPlace,
  fromID = fromPlace$id,
  toID = toPlace$id,
  mode = "CAR"
)

## Visualising routes
tm_shape(routes_drive_top) +
  tm_lines(col = "blue", lwd = 3)

## Joining routes to create a route network
# Load more comprehensive route data
routes_drive = read_sf("https://github.com/ITSLeeds/TDS/releases/download/22/routes_drive.geojson")
routes_transit = read_sf("https://github.com/ITSLeeds/TDS/releases/download/22/routes_transit.geojson")
# Check the dimensions of these datasets
names(desire_lines)
dim(desire_lines)
names(routes_drive)
dim(routes_drive)
dim(routes_transit)

# Joining desire lines to routes
routes_transit_joined = dplyr::left_join(
  routes_transit |>
    rename(from = fromPlace, to = toPlace),
  desire_lines |>
    sf::st_drop_geometry()
)

routes_drive_joined = dplyr::left_join(
  routes_drive |>
    rename(from = fromPlace, to = toPlace),
  desire_lines |>
    sf::st_drop_geometry()
)

# Create route network by aggregating overlapping routes
rnet_drive = overline(routes_drive_joined, "drive")

# Visualising route networks
tm_shape(rnet_drive) +
  tm_lines(
    col = "drive",
    col.scale = tm_scale_intervals(values = "-viridis", style = "jenks"),
    lwd = 2
  )

### Exercise 6.1: Mapping route in Leeds
from = geo_code("Leeds City Museum")
to = geo_code("Clayton Hotel Leeds")
walk_path = otp_plan(otpcon = otpcon,
                     fromPlace = from,
                     toPlace = to,
                     mode = "WALK")

qtm(walk_path)

### Exercise 6.2: Multi-modal routing
transit_path = otp_plan(otpcon = otpcon,
                     fromPlace = from,
                     toPlace = to,
                     mode = c("WALK", "TRANSIT"))

qtm(transit_path)

bike_path = otp_plan(otpcon = otpcon,
                     fromPlace = from,
                     toPlace = to,
                     mode = c("BICYCLE", "TRANSIT"))

qtm(bike_path)