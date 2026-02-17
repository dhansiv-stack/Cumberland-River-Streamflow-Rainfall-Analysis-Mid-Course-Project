library(tidyverse)
library(lubridate)         # For working with dates (extract year, month, etc.)
library(broom)             # For turning model results into clean data frames
library(stringr)           # For working with strings
library(sf)


# merge the wide format of muti-station rainfall data with daily_flow data

merge_wide_daily_flow <- usgs_daily_clean |>
  rename(flow_cfs = value) |>
  left_join(
    rainfall_wide,
    by = "date"
  )

head(merge_wide_daily_flow, 2)

reg_df <- merge_wide_daily_flow |>
  
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

head(reg_df, 2)


# Keep only complete cases for the variables in the model

reg_bna <- reg_df |>
  drop_na(flow_cfs, rainfall_BNA)

model1 <- lm(flow_cfs ~ rainfall_BNA, data = reg_bna)
summary(model1)

# Add BNA variables for lagged in the model2

reg_bna_lag <- reg_df |>
  arrange(date) |>
  mutate(
    rainfall_BNA_lag1 = lag(rainfall_BNA, 1),
    rainfall_BNA_lag2 = lag(rainfall_BNA, 2)
  )

model2 <- lm(flow_cfs ~ rainfall_BNA_lag1 + rainfall_BNA_lag2, data = reg_bna_lag)
summary(model2)

# Add multiple stations rainfall variables in the model

model_multi <- lm(
  flow_cfs ~ rainfall_BNA + rainfall_ASH + rainfall_CKV,
  data = reg_df
)

summary(model_multi)

# Add lagged rainfall for each station in the model

reg_multi_lag <- reg_df |>
  arrange(date) |>
  mutate(
    rainfall_BNA_lag1 = lag(rainfall_BNA, 1),
    rainfall_BNA_lag2 = lag(rainfall_BNA, 2),
    rainfall_MRB_lag1 = lag(rainfall_MRB, 1),
    rainfall_MRB_lag2 = lag(rainfall_MRB, 2),
    rainfall_ASH_lag1 = lag(rainfall_ASH, 1),
    rainfall_ASH_lag2 = lag(rainfall_ASH, 2),
    rainfall_CKV_lag1 = lag(rainfall_CKV, 1),
    rainfall_CKV_lag2 = lag(rainfall_CKV, 2)
    
  )

model_multi_lag <- lm(
  flow_cfs ~ 
    rainfall_BNA_lag1 + rainfall_BNA_lag2+
    rainfall_MRB_lag1 + rainfall_MRB_lag2+
    rainfall_ASH_lag1 + rainfall_ASH_lag2 +
    rainfall_CKV_lag1 + rainfall_CKV_lag2,
  data = reg_multi_lag
)

tidy(model_multi_lag)
summary(model_multi_lag)

confint(model_multi_lag)


# Include target lag in the model

reg_rain_flow_lag <- reg_multi_lag |>
  arrange(date) |>
  mutate(
    flow_cfs_lag1 = lag(flow_cfs, 1),
    flow_cfs_lag2 = lag(flow_cfs, 2)
  ) |>
  
  drop_na(
    flow_cfs_lag1, flow_cfs_lag2,
    rainfall_BNA_lag1, rainfall_BNA_lag2,
    rainfall_MRB_lag1, rainfall_MRB_lag2,
    rainfall_ASH_lag1, rainfall_ASH_lag2,
    rainfall_CKV_lag1, rainfall_CKV_lag2
  )

# Fit model that includes flow lags + rainfall lags

model_rain_flow_cfs_lag <- lm(
  flow_cfs ~ flow_cfs_lag1 + flow_cfs_lag2 +
    rainfall_BNA_lag1 + rainfall_BNA_lag2+
    rainfall_MRB_lag1 + rainfall_MRB_lag2+
    rainfall_ASH_lag1 + rainfall_ASH_lag2 +
    rainfall_CKV_lag1 + rainfall_CKV_lag2,
  data = reg_rain_flow_lag
)


summary(model_rain_flow_cfs_lag)

# Fit model that includes flow lags only

model_flow_cfs_lag <- lm(
  flow_cfs ~ flow_cfs_lag1 + flow_cfs_lag2, data = reg_rain_flow_lag
)

summary(model_flow_cfs_lag)

# Prepare regression results for plotting
# Define place names

station_names <- c(
  "BNA" = "Nashville Airport",
  "MRB" = "Murpreesboro",
  "CKV" = "Clarksville",
  "ASH" = "Ashland City"
)

#  Build combined coefficient table for BOTH models 

coef_both <- bind_rows(
  tidy(model_multi_lag, conf.int = TRUE) |>
    mutate(model = "Flow + rainfall"),
  
  tidy(model_rain_flow_cfs_lag, conf.int = TRUE) |>
    mutate(model = "Rainfall only")
) |>
  # drop intercept
  
  filter(term != "(Intercept)") |>
  
  # classify station / flow terms
  
  mutate(
    station = case_when(
      str_detect(term, "BNA")       ~ "BNA",
      str_detect(term, "MRB")       ~ "MRB",
      str_detect(term, "ASH")       ~ "ASH",
      str_detect(term, "CKV")       ~ "CKV",
      str_detect(term, "flow_cfs")  ~ "Flow",   # flow_lag terms
      TRUE                          ~ "Other"
    ),
    lag = case_when(
      str_detect(term, "lag1") ~ "Lag 1",
      str_detect(term, "lag2") ~ "Lag 2",
      TRUE                     ~ "None"
    ),
    
    # labels for plotting
    
    term_label = case_when(
      station == "Flow" & lag == "Lag 1" ~ "Yesterday's flow (Lag 1)",
      station == "Flow" & lag == "Lag 2" ~ "Flow 2 days ago (Lag 2)",
      
      station %in% names(station_names)  ~ paste0(station_names[station], " (", lag, ")"),
      TRUE                               ~ term
    )
  ) |>
  
  mutate(
    
    # rank stations by importance
    
    station_rank = case_when(
      station == "Flow" ~ 6L,        # put flow lags at very top
      station == "BNA"  ~ 5L,        # Nashville Airport
      station == "CKV"  ~ 4L,        # Clarksville
      station == "ASH"  ~ 3L,        # Ashland City
      station == "MRB"  ~ 2L,        # Murfreesboro
      TRUE              ~ 0L
    ),
    # Lag 1 above Lag 2
    
    lag_rank = case_when(
      lag == "Lag 1" ~ 2L,
      lag == "Lag 2" ~ 1L,
      TRUE           ~ 0L
    )
  ) |>
  
  
  arrange(station_rank, lag_rank) |>
  mutate(
    term_label = factor(term_label, levels = unique(term_label))
  ) |>
  ungroup()

# quick check

coef_both |> select(model, term, term_label, estimate) 

# Side-by-side coefficient plot

gg_coef_both <- ggplot(
  coef_both,
  aes(x = estimate, y = term_label, color = station)
) +
  geom_point(size = 2.8) +
  geom_errorbarh(
    aes(xmin = conf.low, xmax = conf.high),
    height = 0.15
  ) +
  geom_vline(
    xintercept = 0,
    linetype   = "dashed",
    color      = "red",
    linewidth  = 0.7
  ) +
  
  facet_wrap(~ model, nrow = 1) +
  
  scale_color_manual(
    name   = "Predictor",
    values = c(
      "ASH"  = "orange3",
      "BNA"  = "darkgreen",
      "CKV"  = "purple4",
      "MRB"  = "red3",
      "Flow" = "grey20"   # flow_lag1 / flow_lag2
    )
  ) +
  
  labs(
    title    = "Effect of Rainfall and Flow Memory on Cumberland River Discharge",
    subtitle = "Right: rainfall lag only model  |   Left: flow lag + rainfall lag model",
    x        = "Change in daily flow (cfs) per 1 unit of predictor",
    y        = "Predictor (station and lag)"
  ) +
  
  theme_minimal(base_size = 14) +
  theme(
    plot.title    = element_text(hjust = 0.5, face = "bold", size = 16),
    plot.subtitle = element_text(hjust = 0.5, size = 11),
    panel.border  = element_rect(color = "black", fill = NA, linewidth = 0.8),
    axis.line     = element_line(color = "black", linewidth = 0.4),
    axis.title.x  = element_text(size = 12),
    axis.title.y  = element_text(size = 12),
    axis.text.y   = element_text(size = 10),
    axis.ticks        = element_line(color = "grey40"),
    axis.ticks.length = unit(3, "pt"),
    legend.position = "right"
  )


ggsave(
  filename = "figures/reg_coefficients_rain_vs_flow_lag.png",
  plot     = gg_coef_both,
  width    = 12,   # inches
  height   = 6,    # inches
  dpi      = 300
)




