# 1_download_usgs_data.R
# NSS Midcourse: Cumberland River Streamflow Project (USGS 03431500)
# Download raw USGS daily discharge data as JSON

library(tidyverse)  # loads dplyr, tidyr, ggplot2, etc.
library(httr)       # for API
library(jsonlite)   # for JSON




# 1. Set site and parameter information
site <- "03431500"        # The gauge ID for Cumberland River at Nashville
parameter_code <- "00060" # Code for Discharge (cfs)

# 2. API endpoint
url <- "https://waterservices.usgs.gov/nwis/dv/"

# 3. Query parameters
params <- list(
  format = "json",
  sites = site,
  parameterCd = parameter_code,
  startDT = "2010-09-30",
  endDT = "2024-12-31"
)

# 4. Send request
response <- httr::GET(url, query = params)
status_code(response)
response



# 5 Extract raw JSON text and save raw JSON
usgs_text <- httr::content(response, as = "text", encoding = "UTF-8") # "UTF-8" is standard text encoding"
write(usgs_text, "data_raw/usgs_raw_jason.json")