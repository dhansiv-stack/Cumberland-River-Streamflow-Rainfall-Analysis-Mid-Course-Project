library(tidyverse)
library(lubridate)

# Load merged clean data
merged_acf_data <- read_csv(
  "data_clean/usgs_rainfall_seasonal_clean.csv",
  show_col_types = FALSE
)
nrow(merged_acf_data)

# Prepare daily streamflow
flow_daily <- merged_acf_data |>
  arrange(date) |>
  select(date, value) |>
  mutate(
    value = as.numeric(value)   # make sure numeric
  ) |>
  filter(!is.na(value))
nrow(flow_daily)

# ACF of daily streamflow (up to 30 days)
acf(
  flow_daily$value,
  lag.max = 30,
  main = "ACF of Daily Streamflow (Cumberland River)"
)

# Lag-1 autocorrelation (today vs yesterday)
lag1 <- cor(
  flow_daily$value[-1],                  
  flow_daily$value[-nrow(flow_daily)],   
  use = "complete.obs"
)

# Lag-7 autocorrelation (today vs 7 days ago)
lag7 <- cor(
  flow_daily$value[-(1:7)],               
  flow_daily$value[1:(nrow(flow_daily) -7)],
  use = "complete.obs"
)

cat("Lag-1 autocorrelation:", round(lag1, 3), "\n")
cat("Lag-7 autocorrelation:", round(lag7, 3), "\n")

# Day_to_day Change Histogram

day_change <- flow_daily |>
  mutate(
    change = value-lag(value)) |>
  filter(!is.na(change))

png("figures/acsf_day_change_hist.png",
    width = 800,  # in pixels
    height = 500,
    res = 120)

ggplot(day_change, aes(x= change)) +
  geom_histogram(
    bins = 40,
    fill = "skyblue",
    color = "black"
  ) +
  
  labs(
    title = "Histogram of Day-to-Day Change in Streamflow",
    x = "Change in Flow(cfs)",
    y = "Frequency"
  ) +
  
  theme_minimal(base_size = 15) +
theme(
  plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
  panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
  axis.line    = element_line(color = "black", linewidth = 0.8),
  axis.title   = element_text(size = 10),
  axis.title.x = element_text(size = 13),
  axis.title.y = element_text(size = 13)
)
dev.off()

# Week_to_week Change Histogram

week_change <- flow_daily |>
  mutate(
    change = value-lag(value, 7)) |>
  filter(!is.na(change))

png("figures/acf_week_change_hist.png",
    width = 800,  # in pixels
    height = 500,
    res = 120)

ggplot(week_change, aes(x= change)) +
  geom_histogram(
    bins = 40,
    fill = "orange",
    color = "black"
  ) +
  
  labs(
    title = "Histogram of Week-to-Week Change in Streamflow",
    x = "Change in Flow(cfs)",
    y = "Frequency"
  ) +
  
  theme_minimal(base_size = 15) +
theme(
  panel.background = element_rect(fill = "white", color = NA),  # ADD THIS
  panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
  axis.line    = element_line(color = "black", linewidth = 0.8),
  plot.title   = element_text(hjust = 0.5, face = "bold", size = 16),
  axis.title.x = element_text(size = 13),
  axis.title.y = element_text(size = 13)
)
dev.off()