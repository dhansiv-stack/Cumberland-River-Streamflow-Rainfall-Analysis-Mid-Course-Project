server <- function(input, output, session) {
  
  # ---- Filter data for the selected year (daily data) ----
  year_filt_daily_data <- reactive({
    merged_data |>
      filter(year == input$year)
  })
  
  # summary/story 
  output$story_title <- renderText({
    paste("Summary for", input$year)
  })
  
  output$story_summary <- renderPrint({
    
    summary_data <- year_filt_daily_data()
    
    if (nrow(summary_data) == 0) {
      return("No data available for this year.")
    }
    
    total_rain <- sum(summary_data$rain_in, na.rm = TRUE)
    mean_flow  <- mean(summary_data$value,   na.rm = TRUE)
    max_flow   <- max(summary_data$value,   na.rm = TRUE)
    
    # Pick the date where the flow is maximum
    date_max   <- summary_data$date[which.max(summary_data$value)]
    
    glue(
      "Cumberland River at Nashville (USGS 03431500)
      Year: {input$year}
      
      Average daily discharge (cfs): {round(mean_flow, 0)}
      Maximum daily discharge (cfs): {round(max_flow, 0)} on {format(date_max, '%Y-%m-%d')}
      Total annual rainfall at BNA (inches): {round(total_rain, 1)}"
    )
  })
  
  # Daily Time Series: discharge 
  output$discharge_plot <- renderPlot(res = 120, {
    
    data <- year_filt_daily_data()
    
    ggplot(data, aes(x = date, y = value)) +
      geom_line(color = "steelblue", linewidth = 0.7) +
      scale_x_date(
        date_breaks = "1 month",
        date_labels = "%b\n%Y",
        expand      = expansion(mult = c(0.01, 0.01))
      ) +
      scale_y_continuous(labels = label_comma()) +
      geom_smooth(
        method    = "loess",
        span      = 0.15,
        se        = FALSE,
        color     = "red",
        linewidth = 1
      ) +
      labs(
        title = paste("Daily Discharge", input$year),
        x     = "Date",
        y     = "Discharge (cfs)"
      ) +
      theme_minimal(base_size = 15) +
      theme(
        plot.title   = element_text(hjust = 0.5, face = "bold", size = 15),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
        axis.line    = element_line(color = "black"),
        axis.title   = element_text(size = 10),
        axis.text    = element_text(size = 8),
        axis.ticks        = element_line(color = "grey40"),
        axis.ticks.length = unit(4, "pt")
      )
  })
  
  # Seasonal Patterns: boxplot by season (using daily data) ----
  output$season_boxplot <- renderPlot(res = 120, {
    
    data <- year_filt_daily_data() |>
      mutate(
        month  = lubridate::month(date),
        season = case_when(
          month %in% 3:5   ~ "Spring",
          month %in% 6:8   ~ "Summer",
          month %in% 9:11  ~ "Fall",
          TRUE             ~ "Winter"
        ),
        season = factor(season, levels = c("Winter", "Spring", "Summer", "Fall"))
      )
    
    ggplot(data, aes(x = season, y = value, fill = season)) +
      geom_boxplot() +
      scale_y_continuous(labels = label_comma()) +
      labs(
        title = paste("Seasonal Distribution of Daily Discharge", input$year),
        x     = "Season",
        y     = "Discharge (cfs)"
      ) +
      theme_minimal(base_size = 15) +
      theme(
        plot.title   = element_text(hjust = 0.5, face = "bold", size = 15),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
        axis.line    = element_line(color = "black"),
        axis.title   = element_text(size = 10),
        axis.text    = element_text(size = 8),
        axis.ticks        = element_line(color = "grey40"),
        axis.ticks.length = unit(4, "pt")
      )
  })
  
  # 
  output$rainfall_plot <- renderPlot(res = 120, {
    
    data <- year_filt_daily_data()   # ✅ fixed name
    
    ggplot(data, aes(x = date, y = rain_in)) +
      geom_col(fill = "steelblue") +
      scale_x_date(
        date_breaks = "1 month",
        date_labels = "%b\n%Y",
        expand      = expansion(mult = c(0.01, 0.01))
      ) +
      geom_smooth(
        method    = "loess",
        span      = 0.15,
        se        = FALSE,
        color     = "red",
        linewidth = 1
      ) +
      labs(
        title = paste("Daily Rainfall at BNA", input$year),
        x     = "Date",
        y     = "Rainfall (inches)"
      ) +
      theme_minimal(base_size = 15) +
      theme(
        plot.title   = element_text(hjust = 0.5, face = "bold", size = 15),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
        axis.line    = element_line(color = "black"),
        axis.title   = element_text(size = 10),
        axis.text    = element_text(size = 8),
        axis.ticks   = element_line(color = "grey40"),
        axis.ticks.length = unit(4, "pt")
      )
  })
  
  # Streamflow vs Rainfall: scatter plot
  output$streamflow_rainfall_scatter_plot <- renderPlot(res = 120, {
    
    data <- year_filt_daily_data()
    
    ggplot(data, aes(x = rain_in, y = value)) +
      geom_point(alpha = 0.6) +
      labs(
        title = paste("Daily Streamflow vs Daily Rainfall", input$year),
        x     = "Daily Rainfall (inches)",
        y     = "Discharge (cfs)"
      ) +
      theme_minimal(base_size = 15) +
      theme(
        plot.title   = element_text(hjust = 0.5, face = "bold", size = 15),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
        axis.line    = element_line(color = "black"),
        axis.title   = element_text(size = 10),
        axis.text    = element_text(size = 8),
        axis.ticks  = element_line(color = "grey40"),
        axis.ticks.length = unit(4, "pt")
      )
  })
  
  # Map: USGS gage + BNA station rainfall
  
  output$station_map <- renderLeaflet({
    leaflet() |>
      addProviderTiles(providers$Esri.WorldImagery) |>
      setView(lng = gage_lng, lat = gage_lat, zoom = 12) |>
      
      
      addCircleMarkers(
      lng = gage_lng,
      lat = gage_lat,
      radius = 6,
      color = "blue",
      fillOpacity = 0.8,
      popup = "Daily discharge (value, cfs)"
  ) |>
    
    # BNA rainfall station
    addCircleMarkers(
      lng = bna_lng,
      lat = bna_lat,
      radius = 6,
      color = "red",
      fillOpacity = 0.8,
      popup = "Daily rainfall at BNA (rain_in inches)"
    )
  })
  
   
                  
  
}