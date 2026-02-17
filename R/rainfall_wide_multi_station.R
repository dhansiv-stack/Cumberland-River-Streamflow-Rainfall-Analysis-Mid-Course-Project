library(tidyverse)
library(lubridate)

# Convert the data frame from longer to wider

rainfall_wide_daily <- rainfall_multi_s_daily_clean |>
  select(station, date, rain_in) |>
  
  tidyr::pivot_wider(
    
    id_cols = date,             # Identifier column, each row is a date
    names_from = station,       # new columns for station names
    values_from = rain_in,      # fill the column with rainfall in inches
    names_prefix = "rainfall_"
  )
  
names(rainfall_wide_daily)
head(rainfall_wide_daily, 3)


write_csv(rainfall_wide_daily, "data_clean/rainfall_wide_multi_station.csv")
head(read_csv("./data_clean/rainfall_wide_multi_station.csv"), 2)