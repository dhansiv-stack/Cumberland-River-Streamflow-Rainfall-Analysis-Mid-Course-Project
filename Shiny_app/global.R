# global.R 

library(shiny)
library(tidyverse)
library(lubridate)
library(glue)
library(scales)
library(broom)
library(slider)

# For map (desktop version)
library(sf)
library(ggspatial)
library(ggrepel)


# 1) Load base dataset (flow + BNA rain)

merged_data <- readr::read_csv("data/merged_usgs_nashville_rainfall_daily.csv",
                               show_col_types = FALSE) |>
  dplyr::mutate(
    date = as.Date(date),
    year = lubridate::year(date)
  ) |>
  dplyr::select(
    year,
    date,
    value,      # discharge (cfs)
    rain_in,    # BNA daily rain (in)
    qualifiers
  )
merged_data


# 2) Map objects (gg_mrb_map)

source("data/Create_map.R")


# 3) ACF object (for ACF tab)

acf_flow <- stats::acf(
  merged_data$value,
  lag.max   = 30,
  plot      = FALSE,
  na.action = na.exclude
)


# 4) Model comparison datasets (BNA vs All stations; exclude SCX)

rain_wide_daily <- readr::read_csv("data/rainfall_wide_multi_station.csv",
                                   show_col_types = FALSE) |>
  dplyr::mutate(date = as.Date(date))

model_df_base <- merged_data |>
  dplyr::select(date, value) |>
  dplyr::left_join(rain_wide_daily, by = "date") |>
  dplyr::arrange(date) |>
  dplyr::mutate(flow_lag1 = dplyr::lag(value, 1))

# BNA-only dataset

df_flow_bna_rain <- model_df_base |>
  tidyr::drop_na(value, flow_lag1, rainfall_BNA)

# All-stations dataset (NO SCX)

df_flow_all_rain <- model_df_base |>
  tidyr::drop_na(value, flow_lag1, rainfall_BNA, rainfall_ASH, rainfall_CKV, rainfall_MRB)


# 5) Model comparison helper

make_compare_tbl <- function(model_list) {
  purrr::imap_dfr(model_list, \(fit, name) {
    broom::glance(fit) |>
      dplyr::transmute(
        Model = name,
        n = stats::nobs(fit),
        r.squared,
        adj.r.squared,
        AIC
      )
  }) |>
    dplyr::mutate(
      Model = factor(Model, levels = names(model_list)),
      delta_AIC = AIC - min(AIC)
    ) |>
    dplyr::mutate(
      dplyr::across(c(r.squared, adj.r.squared), ~ round(.x, 3)),
      AIC = round(AIC, 0),
      delta_AIC = round(delta_AIC, 0)
    )
}


# 6) Fit models + assemble comparison table


# BNA only

m_bna_rain           <- lm(value ~ rainfall_BNA, data = df_flow_bna_rain)
m_flow_lag1_bna      <- lm(value ~ flow_lag1, data = df_flow_bna_rain)
m_bna_rain_flow_lag1 <- lm(value ~ rainfall_BNA + flow_lag1, data = df_flow_bna_rain)

models_bna <- list(
  "Flow ~ BNA Rainfall"             = m_bna_rain,
  "Flow ~ Flow Lag1"                = m_flow_lag1_bna,
  "Flow ~ BNA Rainfall + Flow Lag1" = m_bna_rain_flow_lag1
)

tbl_bna <- make_compare_tbl(models_bna)

# All stations (NO SCX)

m_all_rain           <- lm(value ~ rainfall_BNA + rainfall_ASH + rainfall_CKV + rainfall_MRB,
                           data = df_flow_all_rain)
m_flow_lag1_all      <- lm(value ~ flow_lag1, data = df_flow_all_rain)
m_all_rain_flow_lag1 <- lm(value ~ rainfall_BNA + rainfall_ASH + rainfall_CKV + rainfall_MRB + flow_lag1,
                           data = df_flow_all_rain)

models_all_stations <- list(
  "Flow ~ All Stations Rainfall"              = m_all_rain,
  "Flow ~ Flow Lag1"                          = m_flow_lag1_all,
  "Flow ~ All Stations Rainfall + Flow Lag1"  = m_all_rain_flow_lag1
)

tbl_all_stations <- make_compare_tbl(models_all_stations)

all_stations_compare_tbl <- dplyr::bind_rows(
  tbl_bna          |> dplyr::mutate(Group = "BNA only"),
  tbl_all_stations |> dplyr::mutate(Group = "All stations")
) |>
  dplyr::select(Group, Model, n, r.squared, adj.r.squared, AIC, delta_AIC)