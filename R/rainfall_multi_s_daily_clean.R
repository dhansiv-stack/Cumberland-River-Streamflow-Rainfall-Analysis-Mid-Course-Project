library(tidyverse)
library(lubridate)
library(sf)
# Read the raw data of multiple rainfall stations
rainfall_multi_s_hourly_clean <- read_csv("data_raw/rainfall_multi_s_hourly_raw.csv")
rainfall_multi_s_hourly_clean |> count(station)
rainfall_multi_s_hourly_clean <- rainfall_multi_s_hourly_clean |>
  mutate(
    date    = as_date(valid),
    rain_in = as.numeric(p01i)
  ) |>
  filter(!is.na(date)) |>
  mutate(
    rain_in = if_else(rain_in < 0, 0, rain_in)   # set negatives to 0
  )

rainfall_multi_s_hourly_clean |>
  select(station, valid, date, p01i, rain_in) |>
  head(5)


# Group by day and station
rainfall_multi_s_daily_clean <- rainfall_multi_s_hourly_clean |>
  group_by(station, date) |>
  summarize(
    rain_in = sum(rain_in, na.rm = TRUE),   # b use cleaned values
    rain_mm = rain_in * 25.4,               # convert to mm
    .groups = "drop"
  )

head(rainfall_multi_s_daily_clean, 2)

write_csv(rainfall_multi_s_daily_clean, "data_clean/rainfall_multi_s_daily_clean.csv")

# Check station counts
rainfall_multi_s_daily_clean |> count(station)