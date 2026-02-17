# data/Create_map.R
# Cumberland Basin & Stations Map (desktop-only, clean version)

# 1) Rainfall station locations (manual coordinates)
stations_df <- tibble::tribble(
  ~station, ~station_name,  ~lon,     ~lat,
  "BNA",    "BNA Airport",  -86.677,  36.126,
  "CKV",    "Clarksville",  -87.415,  36.622,
  "ASH",    "Ashland City", -87.060,  36.270,
  "MRB",    "Murfreesboro", -86.390,  35.846
)

# 2) Dam locations (manual coordinates)
dams_df <- tibble::tribble(
  ~name,               ~lon,      ~lat,
  "Old Hickory Dam",     -86.647, 36.276,
  "J. Percy Priest Dam", -86.580, 36.089
)

# 3) Safe sf reader (keeps shinyapps from crashing if NLDI fails)

safe_st_read <- function(x, ...) {
  tryCatch(
    sf::st_read(x, quiet = TRUE, ...),
    error = function(e) NULL
  )
}

# Manual nudges (tuned for your basin extent)

station_labels <- stations_df |>
  dplyr::mutate(
    nudge_x = dplyr::case_when(
      station == "CKV" ~ -0.60,
      station == "ASH" ~ -0.55,
      station == "BNA" ~ -0.45,
      station == "MRB" ~ -0.5,
      TRUE ~ 0
    ),
    nudge_y = dplyr::case_when(
      station == "CKV" ~  0.12,
      station == "ASH" ~  0.10,
      station == "BNA" ~ -0.15,
      station == "MRB" ~ -0.15,
      TRUE ~ 0
    )
  )

dam_labels <- dams_df |>
  dplyr::mutate(
    nudge_x = dplyr::case_when(
      name == "Old Hickory Dam"     ~ 0.45,
      name == "J. Percy Priest Dam" ~ 0.45,
      TRUE ~ 0.40
    ),
    nudge_y = 0.13
  )

# 4) Read Basin + Flowlines
cumberland_basin <- safe_st_read(
  "https://api.water.usgs.gov/nldi/linked-data/nwissite/USGS-03431500/basin"
)

flowlines <- safe_st_read(
  "https://api.water.usgs.gov/nldi/linked-data/nwissite/USGS-03431500/navigation/UM/flowlines?distance=900"
)

if (!is.null(cumberland_basin) && !is.null(flowlines)) {
  cumberland_basin <- sf::st_transform(cumberland_basin, 4326)
  flowlines        <- sf::st_transform(flowlines, 4326)
}

# 5) Fallback map (always defined)
gg_mrb_map_fallback <- ggplot2::ggplot() +
  ggplot2::annotate(
    "text",
    x = 0, y = 0,
    label = "Map data unavailable on server.\n(USGS NLDI request failed or timed out)",
    size = 5
  ) +
  ggplot2::theme_void()

# 6) Build map
if (is.null(cumberland_basin) || is.null(flowlines)) {
  
  gg_mrb_map <- gg_mrb_map_fallback
  
} else {
  
  # Bounding box padding (degrees)
  
  bb <- sf::st_bbox(sf::st_union(cumberland_basin, flowlines)) 
  
  pad_left  <- 0.650   # more room for CKV label
  pad_right <- 0.30
  pad_y     <- 0.30
  
  ggplot2::coord_sf(
    xlim = c(bb["xmin"] - pad_left,  bb["xmax"] + pad_right),
    ylim = c(bb["ymin"] - pad_y,     bb["ymax"] + pad_y),
    expand = FALSE
  )
  
  gg_mrb_map <- ggplot2::ggplot() +
    
    # Basin polygon
    
    ggplot2::geom_sf(
      data      = cumberland_basin,
      fill      = scales::alpha("palegreen", 0.40),
      color     = "darkgreen",
      linewidth = 0.7
    ) +
    
    # Flowlines
    
    ggplot2::geom_sf(
      data      = flowlines,
      color     = "royalblue",
      linewidth = 0.6
    ) +
    
    # Stations (colored)
    
    ggplot2::geom_point(
      data  = stations_df,
      ggplot2::aes(x = lon, y = lat, color = station),
      size  = 3.2
    ) +
    
    # MRB highlight
    
    ggplot2::geom_point(
      data  = dplyr::filter(stations_df, station == "MRB"),
      ggplot2::aes(x = lon, y = lat),
      shape  = 21,
      size   = 4,
      stroke = 1.2,
      color  = "black",
      fill   = "purple",
      show.legend = FALSE
    ) +
    
    # Dams
    
    ggplot2::geom_point(
      data  = dams_df,
      ggplot2::aes(x = lon, y = lat),
      shape = 17,
      size  = 3,
      color = "gold"
    ) +
    
    # Station labels (manual nudges)
    
    ggrepel::geom_text_repel(
      data = station_labels,
      ggplot2::aes(x = lon, y = lat, label = station_name, color = station),
      nudge_x = station_labels$nudge_x,
      nudge_y = station_labels$nudge_y,
      size = 3.0,
      segment.color = "grey30",
      seed = 123,
      show.legend = FALSE
    ) +
    
    # Dam labels (manual nudges)
    
    ggrepel::geom_text_repel(
      data = dam_labels,
      ggplot2::aes(x = lon, y = lat, label = name),
      nudge_x            = dam_labels$nudge_x,
      nudge_y            = dam_labels$nudge_y,
      size               = 2.6,
      box.padding        = 0.25,
      point.padding      = 0.20,
      segment.color      = "grey20",
      min.segment.length = 0,
      max.overlaps       = 10,
      force              = 1.5,
      seed               = 123
    ) +
    
    # Scale bar + north arrow
    
    ggspatial::annotation_scale(location = "br", width_hint = 0.30) +
    ggspatial::annotation_north_arrow(
      location    = "tr",
      which_north = "true",
      pad_x       = grid::unit(0.35, "cm"),
      pad_y       = grid::unit(0.25, "cm"),
      style       = ggspatial::north_arrow_fancy_orienteering
    ) +
    
    # Titles / labels
    
    ggplot2::labs(
      title    = "Cumberland River Upstream of Nashville (USGS 03431500)",
      subtitle = "Watershed basin, main-stem flowlines, stations, and dams",
      x        = "Longitude",
      y        = "Latitude",
      color    = "Station"
    ) +
    
    # ONE coord_sf at the END
    
    ggplot2::coord_sf(
      xlim = c(bb["xmin"] - pad_left, bb["xmax"] + pad_right),
      ylim = c(bb["ymin"] - pad_y, bb["ymax"] + pad_y),
      expand = FALSE
    ) +
    
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(size = 11),
      axis.title    = ggplot2::element_text(size = 11),
      axis.text     = ggplot2::element_text(size = 9),
      legend.title  = ggplot2::element_text(face = "bold", size = 11),
      legend.text   = ggplot2::element_text(size = 9),
      panel.border  = ggplot2::element_rect(color = "black", fill = NA, linewidth = 0.8),
      axis.ticks        = ggplot2::element_line(color = "grey40"),
      axis.ticks.length = grid::unit(4, "pt")
    )
}