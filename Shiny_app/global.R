library(tidyverse)  # loads dplyr, tidyr, ggplot2, etc.
library(lubridate)  # for dates
library(shiny)      # for shiny
library(glue)
library(scales)
library(broom)
library(leaflet)


#usgs_rain_seasonal <- read_csv("../data_clean/usgs_rainfall_seasonal_clean.csv")
merged_data <- read_csv("../data_clean/merged_usgs_nashville_rainfall_daily.csv") |>
  mutate(
    year = year(date)
  ) |>
  select(
    year,
    date,
    value,
    rain_in,
    rain_mm,
    qualifiers   
  )
# Map coordinates 
# USGS 03431500 – Cumberland River at Nashville
gage_lat <- 36.171
gage_lng <- -86.784

# BNA Airport rainfall station
bna_lat  <- 36.126
bna_lng  <- -86.677