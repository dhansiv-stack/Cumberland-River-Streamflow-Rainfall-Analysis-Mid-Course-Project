# **Cumberland River Streamflow & Rainfall Analysis**  
## Mid-Course Project — Nashville Software School (NSS)

- Daily streamflow data from **USGS Gauge 03431500 – Cumberland River at Nashville**
- Combined with **multi-station rainfall data** from the **Iowa Environmental Mesonet (IEM)**

This project builds a complete, reproducible hydrologic data pipeline in R and explores how rainfall at different locations influences river discharge at Nashville.

---

### Project Overview

The Cumberland River drains a large watershed upstream of Nashville.  
To understand how rainfall influences the river, this project:

- Downloads **USGS daily streamflow (2010–2024)**
- Downloads rainfall from **five NOAA / RIEM stations**
- Cleans, merges, and reshapes all datasets
- Adds **lagged rainfall features** (1–2 day, 1-week lags)
- Performs **autocorrelation analysis (ACF)**
- Builds **single- and multi-station regression models**
- Creates a **watershed map** (basin polygon, flowlines, dams, rainfall stations)
- Prepares a **model-ready dataset** for EDA and a **Shiny app**

The geospatial visualization clearly shows **which stations lie inside the upstream watershed**, a key requirement for meaningful hydrologic modeling.

```

### Repository Structure

Cumberland-River-Streamflow-Rainfall-Analysis-Mid-Course-Project/
│
├── data_raw/                                   # Raw downloads (never edited)
│   ├── usgs_raw_json.json                      # Original USGS DV JSON for site 03431500
│   ├── rainfall_multi_s_hourly_raw.csv         # Hourly rainfall (CKV, ASH, SCX, MRB, BNA)
│   └── rainfall_nashville_raw.csv              # Hourly rainfall for BNA Airport only
│
├── data_clean/                                 # Cleaned & engineered datasets
│   ├── rainfall_nashville_daily_clean.csv      # Daily rainfall summary for BNA
│   ├── rainfall_multi_s_daily_clean.csv        # Daily rainfall totals for all stations
│   ├── rainfall_wide_multi_station.csv         # Wide format (one row per date, stations as columns)
│   ├── merged_usgs_nashville_rainfall_daily.csv# Streamflow + BNA rainfall (daily)
│   ├── usgs_rainfall_seasonal_clean.csv        # Clean dataset with seasonal categories added
│   ├── usgs_multi_s_rainfall_clean.csv         # Streamflow + all-station rainfall (long format)
│   ├── usgs_daily_clean_data.csv               # Parsed USGS daily discharge data
│   └── (other intermediate CSV/RDS files)      # Additional merged/transformed datasets
│
├── R/                                          # Reproducible R scripts (data pipeline)
│   ├── usgs_raw_json/                          # Folder for raw JSON snapshots
│   ├── usgs_daily_clean_data.R                 # Parse USGS JSON → daily discharge CSV
│   ├── rainfall_nashville_raw.R                # Download raw BNA rainfall
│   ├── rainfall_nashville_daily_clean.R        # Clean and process BNA rainfall
│   ├── rainfall_multi_s_hourly_raw.R           # Download hourly rainfall for all stations
│   ├── rainfall_multi_s_daily_clean.R          # Convert hourly multi-station → daily totals
│   ├── rainfall_wide_multi_station.R           # Convert multi-station rainfall → wide format
│   ├── merged_usgs_nashville_rainfall_daily.R  # Merge streamflow + BNA rainfall
│   ├── usgs_rainfall_seasonal_clean.R          # Add seasonal labels (winter, spring, etc.)
│   ├── usgs_multi_s_rainfall_clean.R           # Merge streamflow + multi-station rainfall
│   ├── usgs_multi_s_rainfall_wide_reg_clean.R  # Final regression-ready dataset (lag features included)
│   ├── autocorrelation_analysis.R              # ACF, lag stats, daily/weekly change histograms
│   ├── maps_cumberland_basin.R                 # Basin polygon + flowlines + dams + stations map
│   └── (future scripts)                        # Additional analysis or modeling scripts
│
├── Shiny_app/                                  # Shiny interactive dashboard
│   ├── app.R                                   # Single-file Shiny version
│   ├── global.R                                # Load data, packages, shared objects
│   ├── ui.R                                    # UI layout for split-file Shiny structure
│   ├── server.R                                # Server logic for Shiny app
│   ├── data/                                   # Subset of cleaned data for app use
│   └── www/                                    # CSS, images, icons used in UI
│
├── figures/                                    # Saved plots and visualizations
│   ├── acf_day_change_hist.png                 # Daily change histogram
│   ├── acf_week_change_hist.png                # Weekly change histogram
│   ├── 
│   ├── reg_coefficients_rain_vs_flow_lag.png      # Lagged regression coefficients
│   ├── cumberland_basin_rainfall_stations.png           # High-resolution watershed map
│   └── 
│
├── docs/                                       # Documentation & project notes
│   ├── midcourse_presentation_slides.Rmd       # Presentation files
│   └──             
│
└── README.md                                   # Project overview, data pipeline, instructions

```

### A High-Resolution Geospatial Figure Showing:

- Cumberland River upstream watershed polygon
- River flowlines leading to the Nashville gauge
- Four upstream rainfall stations (SCX, BNA, CKV, ASH)
- Murfreesboro (MRB) highlighted outside the watershed
- Old Hickory Dam and J. Percy Priest Dam
- North arrow and scale bar

![Cumberland Basin Map](figures/cumberland_basin_rainfall_stations.png)



### Why This Map Is Important

- The map clarifies which rainfall stations influence the Nashville river gauge.
- SCX, BNA, CKV, and ASH lie inside or adjacent to the upstream watershed.
- MRB (Murfreesboro) lies **outside** the upstream Cumberland basin.
- MRB rainfall drains into the Stones River / Percy Priest Lake system and joins the Cumberland **downstream** of USGS Gauge 03431500.
- This explains why MRB coefficients were small or negative in regression models.



### Data Sources

**USGS Daily Streamflow – Daily Values (DV) Service**

- Gauge: 03431500 — Cumberland River at Nashville  
- Parameter: 00060 (Discharge, cfs)  
- Date Range: 2010-09-30 to 2024-12-31  

**NOAA / RIEM Rainfall – Multi-Station**

Five stations included:

- SCX – Springfield
- BNA – Nashville Airport
- CKV – Clarksville
- ASH – Ashland City
- MRB – Murfreesboro (outside watershed)

Using the `riem` package:

- Hourly rainfall downloaded via `riem_measures()`
- Hourly → Daily totals aggregated
- Data reshaped to wide format:

  `date | rainfall_SCX | rainfall_BNA | rainfall_CKV | rainfall_ASH | rainfall_MRB`



## Pipeline Summary

### 1. Download Raw Data
**Scripts:**

- usgs_raw_json.R
- rainfall_multi_s_hourly_raw.R
- rainfall_nashville_raw.R

**Tasks:**

- Download USGS daily discharge for site 03431500.
- Download hourly rainfall for five stations.
- Save raw files to `data_raw/` (never manually edited).



### 2. Clean Each Dataset
**Scripts:**

- usgs_daily_clean_data.R
- rainfall_nashville_daily_clean.R
- rainfall_multi_s_daily_clean.R

**Tasks:**

- Parse USGS JSON (extract `dateTime`, `value`, `qualifiers`).
- Convert streamflow to daily values (`flow_cfs`).
- Aggregate hourly rainfall to daily totals.
- Set negative rainfall values to 0.
- Save cleaned CSVs to `data_clean/`.



### 3. Merge Streamflow and Rainfall
**Scripts:**

- merged_usgs_nashville_rainfall_daily.R  
- usgs_multi_s_rainfall_clean.R  
- rainfall_wide_multi_station.R  

**Tasks:**

- Convert rainfall to wide format (one row per date).
- Columns include:  
  `rainfall_SCX`, `rainfall_BNA`, `rainfall_CKV`, `rainfall_ASH`, `rainfall_MRB`
- Join rainfall with `usgs_daily_clean_data.csv` by date.



## Autocorrelation Analysis
**Script:** autocorrelation_analysis.R

### What Was Computed
- ACF up to 30-day lag
- Lag-1 autocorrelation (today vs yesterday)
- Lag-7 autocorrelation (today vs same weekday last week)

### Key Findings
- Lag-1 autocorrelation ≈ **0.97** (very strong hydrologic memory)
- Lag-7 autocorrelation ≈ **0.79** (more variability week to week)



## Histogram Comparison

### Daily Change in Streamflow
- Difference from yesterday  
- Histogram is narrow → smooth day-to-day behavior

### Weekly Change in Streamflow
- Difference from last week  
- Histogram is wider → weekly storm accumulation effects

**Figures:**

- `figures/acf_day_change_hist.png`
- `figures/acf_week_change_hist.png`


## Regression Modeling Results
**Script:** 

usgs_multi_s_rainfall_wide_reg_clean.R

### single-Station Model (BNA Only)

**Model1:**

`lm(flow_cfs ~ rainfall_BNA)`


- R² ≈ 0.01
- Same-day rainfall has a weak but significant effect



### Lagged Rainfall Model (BNA lag1 + lag2)

**Model2:**

`lm(flow_cfs ~ rainfall_BNA_lag1 + rainfall_BNA_lag2)`


- R² ≈ 0.06  
- Stronger coefficients  
- Indicates a 1–2 day hydrologic response time



### Rainfall-only multi-Station Lagged Model

`model_multi_lag`

`lm(
flow_cfs ~
rainfall_BNA_lag1 + rainfall_BNA_lag2 +
rainfall_SCX_lag1 + rainfall_SCX_lag2 +
rainfall_CKV_lag1 + rainfall_CKV_lag2 +
rainfall_ASH_lag1 + rainfall_ASH_lag2 +
rainfall_MRB_lag1 + rainfall_MRB_lag2)`

### These models use rainfall (same-day or lagged) as the only predictors of streamflow.

- R² values range from 0.01–0.10
- Rainfall coefficients often appear very large (e.g., SCX ~10,000 cfs per inch)
- The model forces rainfall to explain both:
- short-term storm-driven changes
- long-term river persistence (baseflow + dam regulation)

**Interpretation:**

- Rainfall-only models overestimate rainfall effects, because they do not account for the river’s natural inertia.

### Flow_multi-Station rain fall lagged model

`Model_rain_flow_cfs_lag`

`lm(
  flow_cfs ~ flow_cfs_lag1 + flow_cfs_lag2 +
    rainfall_BNA_lag1 + rainfall_BNA_lag2+
    rainfall_MRB_lag1 + rainfall_MRB_lag2+
    rainfall_ASH_lag1 + rainfall_ASH_lag2 +
    rainfall_SCX_lag1 + rainfall_SCX_lag2 +
    rainfall_CKV_lag1 + rainfall_CKV_lag2,
  data = reg_rain_flow_lag
)`

### Key findings:

- R² ≈ 0.952 (excellent)
- Rainfall effects become smaller but more accurate
- SCX (Springfield) shows the strongest hydrologic response
- BNA shows moderate influence
- CKV shows weak influence
- ASH has near-zero effects
- MRB has negligible or negative effects (expected, outside watershed)

**Interpretation:**

- This model isolates the true incremental effect of rainfall after accounting for river inertia.

### Autoregressive (AR) Model Summary (`model_flow_cfs_lag`)

- AR models predict streamflow using its own past values (lag-1 and lag-2).
- Lag-1 flow has a strong positive influence on today’s flow (β₁ ≈ 1.29).
- Lag-2 flow provides a smaller negative adjustment (β₂ ≈ −0.32), modeling recession.
- The AR(2) model explains ~95% of daily streamflow variability (R² ≈ 0.95).
- This reflects the river’s strong short-term persistence and slow day-to-day changes.

### Why Rainfall Coefficients Change Dramatically Between Models

- In rainfall-only models, rainfall must explain both long-term flow persistence and short-term storm effects.
- Coefficients appear unrealistically large.

**In the combined model, flow lags explain persistence.**

- Rainfall coefficients shrink to their hydrologically meaningful size.

**Example:**

- SCX (rainfall only): ~10,000–12,000 cfs per inch
- SCX (flow + rainfall): ~2,400 cfs per inch (lag 1)
- The second value represents the true hydrologic impact.

### Why Murfreesboro (MRB) has no effect

- MRB lies outside the upstream Cumberland watershed.

**Rain falling at Murfreesboro drains into:**

Stones River → J. Percy Priest Lake. Then joins the Cumberland downstream of the Nashville gauge

**Thus:** 

- MRB rainfall cannot change upstream discharge at Nashville. 
- Regression correctly shows near-zero or negative coefficients.

**Interpretation:**

- The model is accurately reflecting watershed geography.

## Scientific Summary

- The Cumberland River shows very strong hydrologic memory
- Rainfall contributes incremental flow increases, strongest from Springfield (SCX)
- SCX lies deep in the upstream basin — hydrologically influential
- BNA shows moderate influence; CKV weak; ASH minimal
- MRB has no effect because it lies outside the watershed
- Combined models match physical watershed behavior and dam operations

## **Overall conclusion:**

- **Streamflow at Nashville is controlled primarily by yesterday’s discharge and secondarily by rainfall within the upstream watershed.**




## Next Steps
- Add seasonal effects (wet/dry)
- Explore nonlinear or GAM models
- Expand Shiny app to include:
  - time series
  - rainfall–flow correlations
  - maps
  - multi-station comparisons
- Explore 3–7 day cumulative rainfall predictors



## Notes on Reproducibility
- Raw data stored in `data_raw/`
- Cleaned data produced through scripts only
- No hand-edited intermediate files
- Pipeline can be rerun end-to-end