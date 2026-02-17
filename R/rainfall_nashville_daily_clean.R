## Rain fall data using Nashville station
library(tidyverse)
library(riem)
library(lubridate)

rain_hourly <- read_csv("data_raw/rainfall_nashville_raw.csv")

head(rain_hourly, 5)
colnames(rain_hourly)
summary(rain_hourly$p01i)

rain_hourly_clean <- rain_hourly |>
  filter(!is.na(p01i)) |>
  mutate(
    hour = floor_date(valid, "hour"),
  ) |>
  group_by(hour) |>
  summarise(
    rain_in = max(p01i, na.rm =TRUE),
    .groups = "drop"
    
  ) 


rain_hourly_clean



#Group by day

rain_daily <- rain_hourly_clean |>
  mutate(
    date =as.Date(hour)
  ) |>
  
  group_by(date) |>
  summarize(
    rain_in = sum(rain_in, na.rm = TRUE), # rainfall in inches
    .groups = "drop"
  )

rain_daily

rain_daily |>
  mutate(year = year(date)) |>
  group_by(year) |>
  summarise(total_rain = sum(rain_in, na.rm = TRUE))

write_csv(rain_daily, "data_clean/rainfall_nashville_daily_clean.csv")
