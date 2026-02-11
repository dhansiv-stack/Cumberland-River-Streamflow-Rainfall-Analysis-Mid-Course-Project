## Rain fall data using Nashville station
library(tidyverse)
library(riem)
library(lubridate)

rain_hourly <- read_csv("data_raw/rainfall_nashville_raw.csv")

head(rain_hourly, 5)
colnames(rain_hourly)
summary(rain_hourly$p01i)

## Convert daily rainfall

rain_daily <- rain_hourly |>
  mutate(
    date = as_date(valid),
    rain_in = p01i) |>
  
  #Group by day
  
  group_by(date) |>
  summarize(
    rain_in = sum(rain_in, na.rm = TRUE), # rainfall in inches
    rain_mm = rain_in * 25.4,            # convert to mm
    .groups = "drop"
  )

rain_daily

write_csv(rain_daily, "data_clean/rainfall_nashville_daily_clean.csv")
