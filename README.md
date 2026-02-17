# **Cumberland River Streamflow & Rainfall Analysis**  
## Mid-Course Project — Nashville Software School (NSS)

- Daily streamflow data from **USGS Gauge 03431500 – Cumberland River at Nashville**
- Combined with **multi-station rainfall data** from the **Iowa Environmental Mesonet (IEM)**

This project builds a complete, reproducible hydrologic data pipeline in R and explores how rainfall at different locations influences river discharge at Nashville.

---

## **Project Motivation**

In May 2010, Nashville experienced a historic flood that dramatically impacted the Cumberland River basin.  
Understanding how rainfall translates into river discharge is not only a statistical question — it is a watershed-scale systems question involving geography, hydrologic memory, and dam regulation.

This project investigates how upstream rainfall stations influence daily discharge at the USGS Nashville gauge (03431500) and evaluates the relative importance of:

- River persistence (lagged discharge)
- Local rainfall
- Multi-station rainfall contributions
- Watershed boundaries

---

## **Project Goals**

- Build a fully reproducible hydrologic data pipeline in R.
- Integrate multi-station rainfall with USGS discharge data.
- Quantify hydrologic memory using autocorrelation analysis.
- Compare rainfall-only vs autoregressive vs combined models.
- Validate statistical results against watershed geography.
- Deliver an interactive Shiny dashboard for exploration.

---

## **Key Insights**

- The Cumberland River shows **extremely strong short-term memory** (Lag-1 ACF ≈ 0.97).
- Rainfall alone explains very little daily variability (R² ≈ 0.01).
- Lagged discharge explains ~95% of flow variability.
- Rainfall provides incremental improvements after accounting for persistence.
- Stations inside the upstream watershed influence discharge.
- Stations outside the watershed (MRB) show negligible impact.
- Statistical results align with physical basin boundaries and dam structure.

---

**Executive takeaway:** The Cumberland River is a persistence-dominated hydrologic system where rainfall provides incremental short-term forcing within watershed boundaries.

---

## Live Interactive Dashboard

The Shiny application is deployed online:

**[Launch the Live App](https://sivaraja-data.shinyapps.io/cumberland-river-analysis/)**

## **Dashboard Sections**

### Part 1 — Hydrologic Exploration

- Annual discharge and rainfall summaries
- Daily discharge and rainfall time series
- 7-day rolling rainfall–flow relationships
- Seasonal discharge patterns
- Autocorrelation (ACF) analysis
- High-resolution watershed map (basin polygon, flowlines, dams, rainfall stations)

### Part 2 — Statistical Modeling

- Lag-1 persistence model (Flow ~ Lag1)
- Combined model (Flow ~ Lag1 + Rainfall)
- Side-by-side “Actual vs Fitted” diagnostics
- Model comparison using R², Adjusted R², and AIC
- Comparison of BNA-only vs multi-station rainfall models

### **Purpose of the Dashboard**

- Translates statistical results into visual interpretation
- Demonstrates hydrologic memory in real time
- Quantifies incremental rainfall effects
- Connects regression results to watershed geography

---

## **Project Overview**

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
│   └──  usgs_daily_clean_data.csv               # Parsed USGS daily discharge data
│   
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
│   └──  maps_cumberland_basin.R                # Basin polygon + flowlines + dams + stations map
│   
├── Shiny_app/                                  
│   ├── global.R                                # Load data, packages, shared objects
│   ├── ui.R                                    # UI layout (tab structure, controls)
│   ├── server.R                                # Server logic (reactive plots & models)
│   ├── data/
│       ├── merged_usgs_nashville_rainfall_daily.csv
│       ├── rainfall_wide_multi_station.csv
│       └── Create_map.R
│                        
│   
│
├── figures/                                    # Saved plots and visualizations
│   ├── acf_day_change_hist.png                 # Daily change histogram
│   ├── acf_week_change_hist.png                # Weekly change histogram
│   ├── reg_coefficients_rain_vs_flow_lag.png   # Lagged regression coefficients
│   ├── cumberland_basin_rainfall_stations.png  # High-resolution watershed map
│   
│
│
└── README.md                                   # Project overview, data pipeline, instructions

```

### A High-Resolution Geospatial Figure Showing:

- Cumberland River upstream watershed polygon
- River flowlines leading to the Nashville gauge
- Three upstream rainfall stations (BNA, CKV, ASH)
- Murfreesboro (MRB) highlighted outside the watershed
- Old Hickory Dam and J. Percy Priest Dam
- North arrow and scale bar

![Cumberland Basin Map](figures/cumberland_basin_rainfall_stations.png)



### Why This Map Is Important

- The map clarifies which rainfall stations influence the Nashville river gauge.
- BNA, CKV, and ASH lie inside or adjacent to the upstream watershed.
- MRB (Murfreesboro) lies **outside** the upstream Cumberland basin.
- MRB rainfall drains into the Stones River / Percy Priest Lake system and joins the Cumberland **downstream** of USGS Gauge 03431500.
- This explains why MRB coefficients were small or negative in regression models.


---

### Data Sources

**USGS Daily Streamflow – Daily Values (DV) Service**

- Gauge: 03431500 — Cumberland River at Nashville  
- Parameter: 00060 (Discharge, cfs)  
- Date Range: 2010-09-30 to 2024-12-31  

**NOAA / RIEM Rainfall – Multi-Station**

Four stations included:

- BNA – Nashville Airport
- CKV – Clarksville
- ASH – Ashland City
- MRB – Murfreesboro (outside watershed)

Using the `riem` package:

- Hourly rainfall downloaded via `riem_measures()`
- Hourly → Daily totals aggregated
- Data reshaped to wide format:
- `date | rainfall_BNA | rainfall_CKV | rainfall_ASH | rainfall_MRB`

---

## Pipeline Summary

### 1. Download Raw Data
**Tasks:**

- Download USGS daily discharge for site 03431500.
- Download hourly rainfall for five stations.
- Save raw files to `data_raw/` (never manually edited).



### 2. Clean Each Dataset

**Tasks:**

- Parse USGS JSON (extract `dateTime`, `value`, `qualifiers`).
- Convert streamflow to daily values (`flow_cfs`).
- Aggregate hourly rainfall to daily totals.
- Set negative rainfall values to 0.
- Save cleaned CSVs to `data_clean/`.



### 3. Merge Streamflow and Rainfall

**Tasks:**

- Convert rainfall to wide format (one row per date).
- Columns include:  
  `rainfall_BNA`, `rainfall_CKV`, `rainfall_ASH`, `rainfall_MRB`
- Join rainfall with `usgs_daily_clean_data.csv` by date.
- Save merged and cleaned csvs to `data_clean/`.

---

## Autocorrelation Analysis

**Script:** `autocorrelation_analysis.R`

### What Was Computed
- ACF up to 30-day lag
- Lag-1 autocorrelation (today vs yesterday)
- Lag-7 autocorrelation (today vs same weekday last week)

### Key Findings
- Lag-1 autocorrelation ≈ **0.97** (very strong hydrologic memory)
- Lag-7 autocorrelation ≈ **0.79** (more variability week to week)



### Histogram Comparison

### Daily Change in Streamflow
- Difference from yesterday  
- Histogram is narrow → smooth day-to-day behavior

### Weekly Change in Streamflow
- Difference from last week  
- Histogram is wider → weekly storm accumulation effects

**Figures:**

- `figures/acf_day_change_hist.png`
- `figures/acf_week_change_hist.png`

---

## Regression Modeling Results

**Script:** 

`usgs_multi_s_rainfall_wide_reg_clean.R`

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
rainfall_CKV_lag1 + rainfall_CKV_lag2 +
rainfall_ASH_lag1 + rainfall_ASH_lag2 +
rainfall_MRB_lag1 + rainfall_MRB_lag2)`

 **These models use rainfall (same-day or lagged) as the only predictors of streamflow.**

- R² values range from 0.01–0.10
- The model forces rainfall to explain both:
- short-term storm-driven changes
- long-term river persistence (baseflow + dam regulation)

**Interpretation:**

- Rainfall-only models overestimate rainfall effects, because they do not account for the river’s natural inertia.


### Autoregressive (AR) Model Summary (`model_flow_cfs_lag`)

- AR models predict streamflow using its own past values (lag-1 and lag-2).
- Lag-1 flow has a strong positive influence on today’s flow (β₁ ≈ 1.29).
- Lag-2 flow provides a smaller negative adjustment (β₂ ≈ −0.32), modeling recession.
- The AR(2) model explains ~95% of daily streamflow variability (R² ≈ 0.95).
- This reflects the river’s strong short-term persistence and slow day-to-day changes.

---

## Scientific Summary 

- The Cumberland River exhibits strong hydrologic memory.
- Yesterday’s discharge is the dominant predictor of today’s flow.
- Rainfall contributes incremental short-term effects.
- Multi-station models focus on rainfall gauges located within or adjacent to the upstream watershed.
- Nearby stations (BNA, CKV, ASH) show modest influence.
- Multi-station rainfall adds only small predictive improvement beyond lagged flow.
- Model behavior aligns with watershed boundaries and dam regulation dynamics.


## Overall Conclusion

**Streamflow at Nashville is primarily controlled by river persistence (lagged discharge), with rainfall providing secondary short-term adjustments from stations within the upstream watershed.**

---

## Notes on Reproducibility

- Raw data stored in `data_raw/`
- Cleaned data produced through scripts only
- No hand-edited intermediate files
- Pipeline can be rerun end-to-end

---