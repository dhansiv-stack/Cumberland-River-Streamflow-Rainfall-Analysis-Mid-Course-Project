library(tidyverse)
library(riem)             # Regional integrated environmental monitoring
library(lubridate)        # For working with dates
library(purrr)

## Download multiple stations rainfall

stations <- c("CKV", "ASH", "SCX", "MRB", "BNA")

rainfall_multi_s_hourly <- purrr:: map_dfr(
  stations,
  ~ riem_measures(
    station = .x,
    date_start = "2010-09-30",
    date_end   = "2024-12-31"
    
  ) |>
    
    mutate(
      station = .x
    )
  
)

# Just inspect

glimpse(rainfall_multi_s_hourly)

names(rainfall_multi_s_hourly)

head(rainfall_multi_s_hourly, 2)



write_csv(rainfall_multi_s_hourly, "data_raw/rainfall_multi_s_hourly_raw.csv")


