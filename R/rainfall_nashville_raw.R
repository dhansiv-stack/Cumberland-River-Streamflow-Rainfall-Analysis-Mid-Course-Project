## Rain fall data using Nashville station
library(tidyverse)
library(riem)
library(lubridate)

## Download Nashville Airport rainfall

rain_hourly <- riem_measures(
  station    = "BNA",
  date_start = "2010-09_30",
  date_end   = "2024_12_31"
)
rain_hourly

write_csv(rain_hourly, "data_raw/rainfall_nashville_raw.csv")