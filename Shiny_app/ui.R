# ui.R
library(shiny)

# Keep content from stretching too wide on desktop
wrap <- function(..., max_width = 1000) {
  div(
    style = sprintf("max-width:%spx; margin:0 auto; padding:0 15px;", max_width),
    ...
  )
}

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      #basin_map_plot { 
        height: 720px !important; 
      }

      .intro-text {
        font-size: 16px;
        line-height: 1.8;
        margin-top: 10px;
      }
    "))
  ),
  
  # Title
  
  titlePanel("Cumberland River: Streamflow & Rainfall"),
  
  tabsetPanel(
    id = "tabs",
    
    tabPanel(
      "Part 1 — Overview",
      fluidRow(
        column(
          width = 4,
          wellPanel(
            selectInput(
              "year",
              "Select Year:",
              choices  = sort(unique(merged_data$year)),
              selected = max(merged_data$year)
            ),
            h4(tags$b("Study Period Overview (2010–2024)")),
            uiOutput("overall_metrics"),
            br(),
            
            hr(),
            h4(tags$b("Year summary")),
            uiOutput("year_metrics")
          )
        ),
        column(
          width = 8,
          h3(textOutput("story_title")),
          verbatimTextOutput("story_summary"),
          br(),
          h4(tags$b("Introduction")),
          div(class = "intro-text",
              tags$ul(
                tags$li("This project investigates daily streamflow dynamics of the Cumberland River at Nashville, Tennessee, using USGS discharge data (Site 03431500) and daily rainfall observations from Nashville International Airport (BNA)."),
                tags$li("The objective of Part 1 is descriptive: to understand how discharge varies across seasons, how rainfall accumulates throughout the year, and how major storm events influence peak-flow behavior."),
                tags$li("By examining annual summaries, seasonal distributions, and daily time series patterns, we establish hydrologic context before moving to statistical modeling in Part 2.")
              )
          )
        )
      )
    ),
    
    # Daily time series and compare it with daily rainfall
    
    tabPanel(
      "Daily Time Series",
      wrap(
        selectInput(
          "year_flow_rain",
          "Select Year:",
          choices  = sort(unique(merged_data$year)),
          selected = max(merged_data$year)
        ),
        br(),
        
        # Discharge section
        fluidRow(
          column(
            width = 4,
            h4("Discharge (cfs)"),
            tags$ul(
              tags$li("Blue line = daily discharge."),
              tags$li("Red line = 7-day rolling mean."),
              tags$li("Large spikes reflect storm-driven flow events."),
              tags$li("Flow shows persistence — changes are gradual.")
            )
          ),
          column(
            width = 8,
            plotOutput("discharge_plot", height = "320px", width = "100%")
          )
        ),
        
        br(), br(),
        
        # Rainfall section 
        
        fluidRow(
          column(
            width = 4,
            h4("Rainfall (BNA)"),
            tags$ul(
              tags$li("Bars = daily rainfall totals."),
              tags$li("Red line = 7-day rolling average."),
              tags$li("Most days have zero rainfall."),
              tags$li("Storm clusters drive cumulative effects.")
            )
          ),
          column(
            width = 8,
            plotOutput("rainfall_plot", height = "320px", width = "100%")
          )
        )
      )
    ),
    
    # Seasonal patterns of rainfall
    
    tabPanel(
      "Seasonal Patterns",
      wrap(
        selectInput(
          "year_season_rain",
          "Select Year:",
          choices  = sort(unique(merged_data$year)),
          selected = max(merged_data$year)
        ),
        br(),
        plotOutput("season_boxplot", height = "500px")
      )
    ),
    
    # Scatter plot for streamflow versus rainfall
    
    tabPanel(
      "Streamflow vs Rainfall",
      wrap(
        selectInput(
          "year_scatter",
          "Select Year:",
          choices  = sort(unique(merged_data$year)),
          selected = max(merged_data$year)
        ),
        br(),
        
        # Daily scatter 
        
        fluidRow(
          column(
            width = 4,
            h4("Daily relationship"),
            tags$ul(
              tags$li("Most points stack at rainfall = 0 (many dry days)."),
              tags$li("Flow is rarely 0 because of baseflow + upstream storage."),
              tags$li("Same-day rain is a weak predictor due to lagged response."),
              tags$li("Trendline helps show the overall direction.")
            )
          ),
          column(
            width = 8,
            plotOutput("scatter_daily", height = "320px", width = "100%")
          )
        ),
        
        br(), br(),
        
        # Rolling 7-day scatter 
        
        fluidRow(
          column(
            width = 4,
            h4("7-day rolling relationship"),
            tags$ul(
              tags$li("Rolling rain = storm sequences (cumulative input)."),
              tags$li("Rolling flow = smoother response (less noise)."),
              tags$li("Relationship becomes clearer than daily scatter."),
              tags$li("Better represents watershed ‘memory’.")
            )
          ),
          column(
            width = 8,
            plotOutput("scatter_roll7", height = "320px", width = "100%")
          )
        ),
        
        strong(textOutput("scatter_correlation")),
        br(),
        uiOutput("scatter_note")
      )
    ),
    
    # Part-2. Spatial context and modeling 
    
    tabPanel(
      "Part 2 — Spatial Context & Modeling",
      wrap(
        # Map first (full width)
        plotOutput("basin_map_plot", height = "720px", width = "100%"),
        br(),
        
        # Notes below (full width)
        div(
          style ="padding:15px",
          h4("Why expand beyond BNA rainfall?"),
          tags$ul(
            tags$li("BNA is only one point measurement; storms can miss BNA but hit upstream sub-basins."),
            tags$li("The Cumberland watershed is large — rainfall varies across space (north vs south, upstream vs downstream)."),
            tags$li("Using multiple stations better represents watershed-wide inputs driving Nashville streamflow."),
            tags$li("This helps reduce bias from relying on a single gauge (especially for localized convective storms).")
          ),
          hr(),
          h4("Why regression matters (Part 2)"),
          tags$ul(
            tags$li("Quantifies how much rainfall explains discharge variability (effect size + direction)."),
            tags$li("Lets us compare models: rainfall-only vs lagged-flow persistence vs combined models."),
            tags$li("Tests whether adding more stations improves prediction after accounting for hydrologic memory."),
            tags$li("Supports objective conclusions using R², AIC, and model comparison.")
          )
        )
      )
    ),
    
    
    # Autocorrelation function of discharge for 30 days
    
    tabPanel(
      "Autocorrelation (ACF)",
      wrap(
        plotOutput("acf_plot", height = "700px"),
        br(),
        uiOutput("acf_note")
      )
    ),
    
    # Lag regression analysis
    
    tabPanel(
      "Lag Regression",
      wrap(
        selectInput(
          "year_lag",
          "Select Year:",
          choices  = sort(unique(merged_data$year)),
          selected = max(merged_data$year)
        ),
        br(),
        
        fluidRow(
          column(
            width = 12,
            uiOutput("lag_reg_note")
          )
        ),
        br(),
        
        fluidRow(
          column(
            width = 12,
            radioButtons(
              inputId = "lag_plot_choice",
              label   = "Select model plot:",
              choices = c(
                "Lag 1 only" = "lagonly",
                "Rain + Lag 1" = "lagrain"
              ),
              
              selected = "lagonly",
              inline   = TRUE
            ),
            plotOutput("lag_plot_selected", height = "420px")
          )
        ),
        
        br(),
        
        h4("Model comparison (same year)"),
        tableOutput("lag_compare_tbl"),
        br(),
        
        h4("Model summaries"),
        fluidRow(
          column(width = 6, verbatimTextOutput("lag_summary_lagonly")),
          column(width = 6, verbatimTextOutput("lag_summary_lagrain"))
        )
      )
    ),
    
    # Multiple regression model comparison
    
    tabPanel(
      "Model Comparison",
      wrap(
        h4("Model Fit Comparison (same dataset)"),
        tableOutput("model_compare_table"),
        br(),
        uiOutput("model_compare_note"),
        plotOutput("r2_bar_plot", height = "400px")
      )
    )
  )
)