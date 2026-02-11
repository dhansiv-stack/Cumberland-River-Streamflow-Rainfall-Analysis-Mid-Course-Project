
library(shiny)

# Define UI for application
ui <- fluidPage(
  
  # Application title
  titlePanel("Cumberland River: Streamflow & Rainfall"),
  
  # Sidebar with a year selector
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "year",
        "Select Year:",
        choices = sort(unique(merged_data$year)),
        selected = max(merged_data$year)
      )
    ),
    
    # Main panel showing the plot
    mainPanel(
      tabsetPanel(
        
        tabPanel(
          "summary/story", 
          h3(textOutput("story_title")),
          verbatimTextOutput("story_summary")
        ),
        
        tabPanel(
          "Daily Time Series",
          plotOutput("discharge_plot", height = "400px", width = "650px")
        ),
        
        tabPanel(
          "Seasonal Patterns",
          plotOutput("season_boxplot", height = "400px", width = "650px")
        ),  
        tabPanel(
          "Rainfall in daily totals",
          plotOutput("rainfall_plot", height = "400px", width = "650px")
        ),
        
        tabPanel(
          "Streamflow vs Rainfall",
          plotOutput("streamflow_rainfall_scatter_plot", 
                     height = "400px", width = "650px")
        ),
        
        tabPanel(
          "Map",
          leafletOutput("station_map", height = "400px", width = "650px")
        ),
        
        tabPanel(
          "Autocorrelation(ACF)",
          plotOutput("acf_plot", "400px", width = "650px"),
          verbatimTextOutput("acf_note")
          
        ),
        
        tabPanel(
          "Lag Regression",
          plotOutput("lag_reg_fitted_vs_actual", height = "400px", width = "650px"),
          verbatimTextOutput("lag_reg_summary")
        )
        
      )  
    )
  )
)



