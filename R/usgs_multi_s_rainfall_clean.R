library(tidyverse)  # loads dplyr, tidyr, ggplot2, etc.
library(lubridate)  # for dates

 
# 1. Read clean multiple stations daily rainfall

rain_multi_s_daily_clean <- read_csv("data_clean/rainfall_multi_s_daily_clean.csv") |>
  mutate(
    date = as_date(date)
  ) |>
  
  select(station, date, rain_in)

rain_multi_s_daily_clean

# 2. Merge daily streamflow + multiple stations daily rainfall

merge_dv_multi_s_dr_clean <- usgs_dv_clean |>
  left_join(
    rain_multi_s_daily_clean,
    by = "date"
  )


names(rain_multi_s_daily_clean)


# 6. Save final merged seasonal dataset

write_csv(merge_dv_multi_s_dr_clean, "data_clean/usgs_multi_s_rainfall_clean.csv")