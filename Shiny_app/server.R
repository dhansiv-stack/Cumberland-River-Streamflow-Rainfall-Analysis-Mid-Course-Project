server <- function(input, output, session) {
  
 
  # Helpers

  year_filter <- function(year_input_id) {
    reactive({
      req(input[[year_input_id]])
      yr <- as.integer(input[[year_input_id]])
      dplyr::filter(merged_data, year == yr)
    })
  }
  

  # 1) Reactive filters

  year_filt_story     <- year_filter("year")
  year_filt_flow_rain <- year_filter("year_flow_rain")
  year_filt_season    <- year_filter("year_season_rain")
  year_filt_scatter   <- year_filter("year_scatter")
  
  lag_data_year <- reactive({
    req(input$year_lag)
    yr <- as.integer(input$year_lag)
    dplyr::filter(lag_data, year == yr)
  })
  

  

  # 2) Overview metrics

  output$year_metrics <- renderUI({
    story <- year_filt_story()
    req(nrow(story) > 0)
    
    flow_mean   <- mean(story$value, na.rm = TRUE)
    flow_median <- median(story$value, na.rm = TRUE)
    flow_peak   <- max(story$value, na.rm = TRUE)
    
    rain_total  <- sum(story$rain_in, na.rm = TRUE)
    rain_mean   <- mean(story$rain_in, na.rm = TRUE)
    rain_median <- median(story$rain_in, na.rm = TRUE)
    rain_peak   <- max(story$rain_in, na.rm = TRUE)
    
    tags$ul(
      tags$li(
        tags$b("Flow (cfs): "),
        glue::glue("Mean {round(flow_mean,0)}, Median {round(flow_median,0)}, Peak {round(flow_peak,0)}")
      ),
      tags$li(
        tags$b("Rain (in): "),
        glue::glue("Total {round(rain_total,1)}, Mean/day {round(rain_mean,2)}, Median/day {round(rain_median,2)}, Peak/day {round(rain_peak,2)}")
      )
    )
  })
  

  # 3) Daily discharge

  output$discharge_plot <- renderPlot({
    df <- year_filt_flow_rain() |>
      dplyr::arrange(date) |>
      dplyr::mutate(
        flow_7d = slider::slide_dbl(value, ~ mean(.x, na.rm = TRUE),
                                    .before = 6, .complete = TRUE)
      )
    
    ggplot2::ggplot(df, ggplot2::aes(x = date, y = value)) +
      ggplot2::geom_line(color = "steelblue", linewidth = 0.7) +
      ggplot2::geom_line(ggplot2::aes(y = flow_7d), color = "red", linewidth = 1) +
      ggplot2::scale_x_date(
        date_breaks = "1 month",
        date_labels = "%b\n%Y",
        expand      = ggplot2::expansion(mult = c(0.01, 0.02))
      ) +
      ggplot2::scale_y_continuous(labels = scales::label_comma()) +
      ggplot2::labs(
        title = paste("Daily discharge", input$year_flow_rain),
        x     = "Date",
        y     = "Discharge (cfs)"
      ) +
      ggplot2::coord_cartesian(ylim = c(0, 110000)) +
      ggplot2::theme_minimal(base_size = 13) +
      ggplot2::theme(
        plot.title        = ggplot2::element_text(hjust = 0.5, face = "bold", size = 15),
        aspect.ratio      = 0.4,
        panel.border      = ggplot2::element_rect(color = "black", fill = NA, linewidth = 1),
        axis.line         = ggplot2::element_line(color = "black"),
        axis.title        = ggplot2::element_text(size = 10),
        axis.text         = ggplot2::element_text(size = 8),
        axis.ticks        = ggplot2::element_line(color = "grey40"),
        axis.ticks.length = grid::unit(4, "pt"),
        plot.margin       = ggplot2::margin(t = 5.5, r = 15, b = 5.5, l = 15)
      )
  }, res = 120)
  

  # 4) Daily rainfall

  output$rainfall_plot <- renderPlot({
    df <- year_filt_flow_rain() |>
      dplyr::arrange(date) |>
      dplyr::mutate(
        rain_7d = slider::slide_dbl(rain_in, ~ mean(.x, na.rm = TRUE),
                                    .before = 6, .complete = TRUE)
      )
    
    ggplot2::ggplot(df, ggplot2::aes(x = date)) +
      ggplot2::geom_col(ggplot2::aes(y = rain_in), width = 2, fill = "steelblue", alpha = 0.6) +
      ggplot2::geom_line(ggplot2::aes(y = rain_7d), color = "red", linewidth = 1) +
      ggplot2::scale_x_date(
        date_breaks = "1 month",
        date_labels = "%b\n%Y",
        expand      = ggplot2::expansion(mult = c(0.01, 0.02))
      ) +
      ggplot2::labs(
        title = paste("Daily Rainfall at BNA", input$year_flow_rain),
        x     = "Date",
        y     = "Rainfall (inches)"
      ) +
      ggplot2::coord_cartesian(ylim = c(0, 5)) +
      ggplot2::theme_minimal(base_size = 13) +
      ggplot2::theme(
        plot.title        = ggplot2::element_text(hjust = 0.5, face = "bold", size = 15),
        aspect.ratio      = 0.40,
        panel.border      = ggplot2::element_rect(color = "black", fill = NA, linewidth = 1),
        axis.line         = ggplot2::element_line(color = "black"),
        axis.title        = ggplot2::element_text(size = 10),
        axis.text         = ggplot2::element_text(size = 8),
        axis.ticks        = ggplot2::element_line(color = "grey40"),
        axis.ticks.length = grid::unit(4, "pt"),
        plot.margin       = ggplot2::margin(t = 5.5, r = 15, b = 5.5, l = 15)
      )
  }, res = 120)
  

  # 5) Seasonal patterns

  output$season_boxplot <- renderPlot({
    df <- year_filt_season() |>
      dplyr::mutate(
        month  = lubridate::month(date),
        season = dplyr::case_when(
          month %in% 3:5  ~ "Spring",
          month %in% 6:8  ~ "Summer",
          month %in% 9:11 ~ "Fall",
          TRUE            ~ "Winter"
        ),
        season = factor(season, levels = c("Winter", "Spring", "Summer", "Fall"))
      )
    
    ggplot2::ggplot(df, ggplot2::aes(x = season, y = value, fill = season)) +
      ggplot2::geom_boxplot() +
      ggplot2::scale_y_continuous(labels = scales::label_comma()) +
      ggplot2::labs(
        title = paste("Seasonal Discharge", input$year_season_rain),
        x     = "Season",
        y     = "Discharge (cfs)"
      ) +
      ggplot2::theme_minimal(base_size = 15) +
      ggplot2::theme(
        plot.title        = ggplot2::element_text(hjust = 0.5, face = "bold", size = 15),
        panel.border      = ggplot2::element_rect(color = "black", fill = NA, linewidth = 1),
        axis.line         = ggplot2::element_line(color = "black"),
        axis.title        = ggplot2::element_text(size = 10),
        axis.text         = ggplot2::element_text(size = 8),
        axis.ticks        = ggplot2::element_line(color = "grey40"),
        axis.ticks.length = grid::unit(4, "pt")
      )
  }, res = 120)

 # 6) Streamflow vs Rainfall tab  

  # Scatter (daily)

  output$scatter_daily <- renderPlot({
    df <- year_filt_scatter()
    
    ggplot2::ggplot(df, ggplot2::aes(x = rain_in, y = value)) +
      ggplot2::geom_point(alpha = 0.6, color = "steelblue") +
      ggplot2::geom_smooth(method = "lm", se = FALSE, color = "red") +
      ggplot2::scale_y_continuous(labels = scales::label_comma()) +
      ggplot2::labs(
        title = paste("Daily Rainfall vs Daily Discharge", input$year_scatter),
        x     = "Daily Rainfall Total (inches)",
        y     = "Daily Discharge (cfs)"
      ) +
      ggplot2::theme_minimal(base_size = 13) +
      ggplot2::theme(
        plot.title        = ggplot2::element_text(hjust = 0.5, face = "bold", size = 15),
        aspect.ratio      = 0.40,
        panel.border      = ggplot2::element_rect(color = "black", fill = NA, linewidth = 1),
        axis.line         = ggplot2::element_line(color = "black"),
        axis.title        = ggplot2::element_text(size = 10),
        axis.text         = ggplot2::element_text(size = 8),
        axis.ticks        = ggplot2::element_line(color = "grey40"),
        axis.ticks.length = grid::unit(4, "pt")
      )
  }, res = 120)
  

  # Scatter (rolling 7-day)

  output$scatter_roll7 <- renderPlot({
    df <- year_filt_scatter() |>
      dplyr::arrange(date) |>
      dplyr::mutate(
        rain_7d = slider::slide_dbl(rain_in, ~ sum(.x, na.rm = TRUE),  .before = 6, .complete = TRUE),
        flow_7d = slider::slide_dbl(value,   ~ mean(.x, na.rm = TRUE), .before = 6, .complete = TRUE)
      ) |>
      dplyr::filter(!is.na(rain_7d), !is.na(flow_7d))
    
    ggplot2::ggplot(df, ggplot2::aes(x = rain_7d, y = flow_7d)) +
      ggplot2::geom_point(alpha = 0.6, color = "steelblue") +
      ggplot2::geom_smooth(method = "lm", se = FALSE, color = "red") +
      ggplot2::scale_y_continuous(labels = scales::label_comma()) +
      ggplot2::labs(
        title = paste("7-day Rolling Rainfall vs 7-day Rolling Discharge", input$year_scatter),
        x     = "7-day Rainfall Total (inches)",
        y     = "7-day Mean Discharge (cfs)"
      ) +
      ggplot2::theme_minimal(base_size = 13) +
      ggplot2::theme(
        plot.title        = ggplot2::element_text(hjust = 0.5, face = "bold", size = 12),
        aspect.ratio      = 0.40,
        panel.border      = ggplot2::element_rect(color = "black", fill = NA, linewidth = 1),
        axis.line         = ggplot2::element_line(color = "black"),
        axis.title        = ggplot2::element_text(size = 10),
        axis.text         = ggplot2::element_text(size = 8),
        axis.ticks        = ggplot2::element_line(color = "grey40"),
        axis.ticks.length = grid::unit(4, "pt")
      )
  }, res = 120)
  
  output$scatter_note <- renderUI({
    tags$div(
      tags$h4(tags$b("Why use a 7-day rolling window?")),
      tags$ul(
        tags$li(tags$b("Daily plot: points pile up at zero rainfall"), " because most days have no rain, creating a vertical cluster at x = 0."),
        tags$li(tags$b("River flow is not zero on dry days"), " due to baseflow, groundwater contributions, upstream storage, and reservoir regulation."),
        tags$li(tags$b("Same-day rainfall is a weak predictor"), " because streamflow responds with delay and integrates rainfall over time."),
        tags$li(tags$b("7-day rolling rainfall (total) captures storm sequences"), " and represents cumulative watershed input."),
        tags$li(tags$b("7-day rolling discharge (mean) smooths short-term noise"), " making the rainfall–streamflow relationship easier to see and explain.")
      ),
      tags$p(tags$b("Takeaway: "), "Rolling windows reflect hydrologic memory and reduce the dominance of zero-rainfall days in the scatter plot.")
    )
  })
  

  # 7) Map 
  
  output$basin_map_plot <- renderPlot({
    gg_mrb_map
  }, res = 120)
  

  # 8) ACF

  output$acf_plot <- renderPlot({
    plot(
      acf_flow,
      main = "ACF of Daily Discharge (All Years)",
      xlab = "Lag (days)",
      ylab = "Autocorrelation"
    )
  }, res = 120)
  
  output$acf_note <- renderUI({
    HTML("
      <ul>
        <li><b>The autocorrelation function (ACF)</b> shows how strongly daily Cumberland River discharge is related to previous days.</li>
        <li><b>High positive correlation at short lags (1–7 days)</b> indicates strong short-term memory in the river system.</li>
        <li>This means streamflow changes gradually rather than randomly from day to day.</li>
        <li>As lag increases, the correlation decays, reflecting the dissipation of hydrologic memory over time.</li>
        <li>This pattern supports including <b>lagged flow terms</b> in the regression model.</li>
      </ul>
    ")
  })
  

  # 9) Lag regression
  
  lag_data <- merged_data |>
    dplyr::arrange(date) |>
    dplyr::mutate(flow_cfs_lag1 = dplyr::lag(value, 1)) |>
    dplyr::filter(!is.na(flow_cfs_lag1))
  
  # Note
  
  
  output$lag_reg_note <- renderUI({
    tags$ul(
      tags$li("Left: persistence-only model (Lag1)."),
      tags$li("Right: adds same-day rainfall to test incremental improvement."),
      tags$li("Compare R² and AIC below to see if rainfall meaningfully helps for that year.")
    )
  })
  
  # Reactive part for plotting

  lag_data_year <- reactive({
    req(input$year_lag)
    yr <- as.integer(input$year_lag)
    dplyr::filter(lag_data, year == yr)
  })
  
  # two models
  model_lag_only <- reactive({
    df <- lag_data_year()
    req(nrow(df) > 30)
    lm(value ~ flow_cfs_lag1, data = df)
  })
  
  model_lag_rain <- reactive({
    df <- lag_data_year()
    req(nrow(df) > 30)
    lm(value ~ flow_cfs_lag1 + rain_in, data = df)
  })
  
  # Two summaries
  
  output$lag_summary_lagonly <- renderPrint(summary(model_lag_only()))
  output$lag_summary_lagrain <- renderPrint(summary(model_lag_rain()))
  
  # Comparison table
  
  output$lag_compare_tbl <- renderTable({
    m1 <- model_lag_only()
    m2 <- model_lag_rain()
    
    tibble::tibble(
      Model = c("Flow ~ Lag1", "Flow ~ Lag1 + Rain"),
      R2    = c(summary(m1)$r.squared, summary(m2)$r.squared),
      Adj_R2= c(summary(m1)$adj.r.squared, summary(m2)$adj.r.squared),
      AIC   = c(AIC(m1), AIC(m2))
    ) |>
      dplyr::mutate(
        dplyr::across(c(R2, Adj_R2), ~ round(.x, 3)),
        AIC = round(AIC, 0),
        delta_AIC = AIC-min(AIC)
      )
  })
# Helper function for the plots
  
  plot_actual_vs_fitted <- function(df, fit, title) {
    df$fitted <- predict(fit, newdata = df)
    
  ggplot2::ggplot(df, ggplot2::aes(x = value, y = fitted)) +
    ggplot2::geom_point(alpha = 0.5, color = "steelblue") +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
    ggplot2::scale_x_continuous(labels = scales::label_comma()) +
    ggplot2::scale_y_continuous(labels = scales::label_comma()) +
    ggplot2::labs(title = title, x = "Actual Discharge (cfs)", y = "Fitted Discharge (cfs)") +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      plot.title        = ggplot2::element_text(hjust = 0.5, face = "bold", size = 10),
      panel.border      = ggplot2::element_rect(color = "black", fill = NA, linewidth = 0.8),
      axis.line         = ggplot2::element_line(color = "black"),
      axis.ticks        = ggplot2::element_line(color = "grey40"),
      axis.ticks.length = grid::unit(4, "pt")
    )
  }
 

  
# Two plots
  
  output$lag_plot_lagonly <- renderPlot({
    df  <- lag_data_year()
    fit <- model_lag_only()
    plot_actual_vs_fitted(df, fit, glue::glue("Actual vs Fitted ({input$year_lag}): Flow ~ Lag1"))
  }, res = 120)
  
  output$lag_plot_lagrain <- renderPlot({
    df  <- lag_data_year()
    fit <- model_lag_rain()
    plot_actual_vs_fitted(df, fit, glue::glue("Actual vs Fitted ({input$year_lag}): Flow ~ Lag1 + Rain"))
  }, res = 120)
  

 
  
  # 10) Model comparison

  output$model_compare_table <- renderTable({
    all_stations_compare_tbl
  })
  
  output$model_compare_note <- renderUI({
    tags$ul(
      tags$li("All Stations = BNA + ASH + CKV + MRB"),
      tags$li("Rainfall alone explains very little daily discharge variability."),
      tags$li("Streamflow persistence (lag1) explains ~94–95% of the variance."),
      tags$li("Rainfall improves prediction slightly after accounting for persistence."),
      tags$li("Including more stations provides marginal improvement.")
    )
  })
  
  output$r2_bar_plot <- renderPlot({
    tbl <- all_stations_compare_tbl |>
      dplyr::mutate(Model = gsub("Rinfall", "Rainfall", Model)) |>
      dplyr::mutate(
        Model_Type = dplyr::case_when(
          grepl("Flow Lag1", Model) & grepl("Rain", Model) ~ "Rain + Lag1",
          grepl("Flow Lag1", Model) ~ "Lag1 Only",
          grepl("Rain", Model) ~ "Rain Only",
          TRUE ~ NA_character_
        ),
        Model_Type = factor(Model_Type, levels = c("Rain Only", "Lag1 Only", "Rain + Lag1"))
      ) |>
      dplyr::filter(!is.na(Model_Type))
    
    ggplot2::ggplot(tbl, ggplot2::aes(x = Model_Type, y = r.squared, fill = Model_Type)) +
      ggplot2::geom_col(width = 0.6) +
      ggplot2::geom_text(ggplot2::aes(label = sprintf("%.3f", r.squared)), vjust = -0.3, size = 4) +
      ggplot2::facet_wrap(~ Group) +
      ggplot2::scale_y_continuous(limits = c(0, 1.05)) +
      ggplot2::labs(title = "R² by Model Type", x = NULL, y = "R²") +
      ggplot2::theme_minimal(base_size = 14) +
      ggplot2::theme(
        strip.text        = ggplot2::element_text(face = "bold"),
        plot.title        = ggplot2::element_text(hjust = 0.5),
        panel.border      = ggplot2::element_rect(color = "black", fill = NA, linewidth = 1),
        axis.line         = ggplot2::element_line(color = "black"),
        axis.title        = ggplot2::element_text(size = 10),
        axis.text         = ggplot2::element_text(size = 8),
        axis.ticks        = ggplot2::element_line(color = "grey40"),
        axis.ticks.length = grid::unit(4, "pt")
      )
  }, res = 120)
  
}