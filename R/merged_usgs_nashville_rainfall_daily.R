library(tidyverse)  # loads dplyr, tidyr, ggplot2, etc.
library(lubridate)  # for dates

# 1. Read clean USGS daily streamflow 

usgs_dv_clean <- read_csv("data_clean/usgs_daily_clean_data.csv")
usgs_dv_clean
# 2. Convert value to numeric and add date column

usgs_flow_clean <- usgs_dv_clean |>
  mutate(
    value = as.numeric(value),
  ) |>
  select(date, value, qualifiers)
usgs_flow_clean

# 3. Read clean daily rainfall

rain_daily_clean <- read_csv("data_clean/rainfall_nashville_daily_clean.csv") |>
  # mutate(
  #   date = as_date(date)
  # ) |>
  select(date, rain_in)

rain_daily_clean
# 4. Merge daily streamflow + daily rainfall

merge_dv_dr_clean <- usgs_flow_clean |>
  left_join(
    rain_daily_clean,
    by = "date"
  )
merge_dv_dr_clean
write_csv(merge_dv_dr_clean, "data_clean/merged_usgs_nashville_rainfall_daily.csv")