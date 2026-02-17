library(tidyverse)
library(lubridate)
library(sf)
# Read the raw data of multiple rainfall stations
rainfall_multi_s_hourly_clean <- read_csv("data_raw/rainfall_multi_s_hourly_raw.csv")

rainfall_multi_s_hourly_clean

rainfall_multi_s_hourly <- rainfall_multi_s_hourly_clean |>
  filter(!is.na(p01i)) |>
  mutate(
    hour = floor_date(valid, "hour"),
  ) |>
  group_by(station, hour) |>
  summarise(
    rain_in = max(p01i, na.rm =TRUE),
    .groups ="drop"
    
  )

rainfall_multi_s_hourly

# Group by day
  
rainfall_multi_s_daily_clean <- rainfall_multi_s_hourly |>
  mutate(
    date =as.Date(hour)
  ) |>
  
  group_by(station, date) |>
  summarize(
    rain_in = sum(rain_in, na.rm = TRUE), # rainfall in inches
    
  )
  

rainfall_multi_s_daily_clean


head(rainfall_multi_s_daily_clean, 2)

write_csv(rainfall_multi_s_daily_clean, "data_clean/rainfall_multi_s_daily_clean.csv")

# Check station counts
rainfall_multi_s_daily_clean |> count(station)