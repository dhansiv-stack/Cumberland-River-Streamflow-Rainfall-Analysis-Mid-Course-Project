# Convert the long json string into an R object

usgs_text <- readLines("data_raw/usgs_raw_json.json")
usgs_list <- jsonlite::fromJSON(usgs_text, simplifyVector = FALSE)

str(usgs_list, max.level = 1)
str(usgs_list$value, max.level = 1)
str(usgs_list$value$timeSeries, max.level = 1)
str(usgs_list$value$timeSeries[[1]], max.level = 1)
str(usgs_list$value$timeSeries[[1]]$values, max.level = 1)
str(usgs_list$value$timeSeries[[1]]$values[[1]], max.level = 1)

value_block <- usgs_list$value$timeSeries[[1]]$values[[1]]
names(value_block)

# This is the list of daily observations

value_list <- value_block$value
length(value_list)
str(value_list[[1]])

# Convert the list-of-lists into a tibble


usgs_daily_clean <- purrr::map_dfr(
  value_list,
  ~ tibble(
    value = as.numeric(.x$value),
    dateTime = .x$dateTime,
    qualifiers = .x$qualifiers[[1]]
  ) 
)

usgs_daily_clean <- usgs_daily_clean |>
  mutate(
    date = as.Date(dateTime)
  ) |>
  
  select(date, value, qualifiers)

glimpse(usgs_daily_clean)
head(usgs_daily_clean, 5)

# Save cleaned USGS daily data

write_csv(usgs_daily_clean, "data_clean/usgs_daily_clean_data.csv")