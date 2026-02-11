library(tidyverse)  # loads dplyr, tidyr, ggplot2, etc.
library(lubridate)  # for dates

merge_dv_dr_data_clean <- merge_dv_dr_clean |>
  mutate(
    year = year(date),
    month = month(date, label = TRUE, abbr = TRUE),
    month_num = month(date),
    season = case_when(
      month_num %in% c(12, 1, 2) ~ "Winter",
      month_num %in% c(3, 4, 5) ~ "Spring",
      month_num %in% c(6, 7, 8) ~ "Summer",
      month_num %in% c(9, 10, 11) ~ "Fall"
      
    )
  )


head(merge_dv_dr_data_clean, 2)

# 6. Save final merged seasonal dataset

write_csv(merge_dv_dr_data_clean, "data_clean/usgs_rainfall_seasonal_clean.csv")