library(tidyverse)
library(lubridate)

# Convert the data frame from longer to wider

rainfall_wide <- rainfall_multi_s_daily_clean |>
  select(station, date, rain_in) |>
  
  tidyr::pivot_wider(
    
    id_cols = date,             # Identifier column, each row is a date
    names_from = station,       # new columns for station names
    values_from = rain_in,      # fill the column with rainfall in inches
    names_prefix = "rainfall_"
  )
  
names(rainfall_wide)
head(rainfall_wide, 3)

na_counts <- rainfall_wide |>
  summarise(across(starts_with("rainfall_"), ~ sum(is.na(.x))))

na_counts

rainfall_wide <- rainfall_wide |>
  mutate(
    across(
      starts_with("rainfall_"),
      ~ replace_na(.x, 0)
    )
  )

colSums(is.na(rainfall_wide |> select(starts_with("rainfall_"))))

names(rainfall_wide)

head(rainfall_wide, 2)

write_csv(rainfall_wide, "data_clean/rainfall_wide_multi_station.csv")