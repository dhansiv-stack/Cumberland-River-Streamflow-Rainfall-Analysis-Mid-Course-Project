# Cumberland Basin & Stations Map
# 1. Libraries 
library(sf)
library(tidyverse)
library(ggspatial)
library(ggrepel)   # for repel labels
library(scales)   # for pretty_breaks

# 2. Rainfall station locations (manual coordinates) 
stations_df <- tribble(
  ~station, ~station_name,       ~lon,     ~lat,    ~is_mrb,
  "BNA",    "BNA Airport",       -86.677,  36.126,  FALSE,
  "CKV",    "Clarksville",       -87.415,  36.622,  FALSE,
  "ASH",    "ASH station",       -87.060,  36.270,  FALSE,
  "MRB",    "Murfreesboro",      -86.390,  35.846,  TRUE
)

# Quick sanity check
stations_df |> select(station, station_name, lon, lat)

# 3. Read Cumberland River upstream basin & flowlines from USGS NLDI 

cumberland_basin <- st_read(
  "https://api.water.usgs.gov/nldi/linked-data/nwissite/USGS-03431500/basin",
  quiet = FALSE
)

flowlines <- st_read(
  "https://api.water.usgs.gov/nldi/linked-data/nwissite/USGS-03431500/navigate/UM",
  quiet = FALSE
)

# 4. Dam locations (plain tibble, we'll plot with lon/lat) 

dams_df <- tribble(
  ~name,               ~lon,      ~lat,
  "Old Hickory Dam",     -86.647, 36.276,
  "J. Percy Priest Dam", -86.580, 36.089
)

# 5. # stations_df, cumberland_basin, flowlines, dams_df already created above

suppressWarnings({
  gg_mrb_map <- ggplot() +
    
    # Watershed polygon
    geom_sf(
      data      = cumberland_basin,
      fill      = scales::alpha("palegreen", 0.3),
      color     = "darkgreen",
      linewidth = 0.4
    ) +
    
    # Main-stem flowlines
    geom_sf(
      data      = flowlines,
      color     = "royalblue",
      linewidth = 0.6
    ) +
    
    # All rainfall stations (for legend)
    geom_point(
      data  = stations_df,
      aes(x = lon, y = lat, color = station),
      size  = 2,
      shape = 19
    ) +
    
    # Extra highlight for MRB only (no legend)
    geom_point(
      data  = stations_df |> filter(station == "MRB"),
      aes(x = lon, y = lat, color = station),  # use palette color
      shape  = 15,
      size   = 3,
      fill   = NA,
      stroke = 1.1,
      show.legend = FALSE
    ) +
    
    # Dams as simple black triangles (no labels, to avoid clutter)
    geom_point(
      data  = dams_df,
      aes(x = lon, y = lat),
      shape = 17,
      size  = 2,
      color = "yellow"
    ) +
    
    # Only the three upstream stations like your original map
    geom_text_repel(
      data = stations_df |> filter(station %in% c("CKV", "ASH", "SCX")),
      aes(x = lon, y = lat, label = station_name, color = station),
      size               = 2,
      box.padding        = 0.35,
      point.padding      = 0.25,
      nudge_y            = 0.04,    # upward a bit
      nudge_x            = -0.15,   # push labels left
      segment.color      = "grey30",
      min.segment.length = 0
    ) +
    
    # Nashville Airport (BNA) ??? its own repel layer
    geom_text_repel(
      data = stations_df |> filter(station == "BNA"),
      aes(x = lon, y = lat, label = station_name, color = station),
      size               = 2,
      box.padding        = 0.35,
      point.padding      = 0.25,
      nudge_y            = -0.04,   # move slightly downward
      nudge_x            = -0.2,   # left so it doesn???t sit on dams
      hjust              = 1,
      segment.color      = "grey30",
      min.segment.length = 0
    ) +
    
    
    # Murfreesboro (MRB) ??? its own repel layer
    geom_text_repel(
      data = stations_df |> filter(station == "MRB"),
      aes(x = lon, y = lat, label = station_name, color = station),
      size               = 2,
      box.padding        = 0.35,
      point.padding      = 0.25,
      nudge_y            = -0.04,   # move slightly downward
      nudge_x            = 0.3,   # left so it doesn???t sit on dams
      hjust              = 1,
      segment.color      = "grey30",
      min.segment.length = 0,
      show.legend        = FALSE
    ) +
    # Dam labels ??? short nudge upward
    
    geom_text_repel(
      data = dams_df,
      aes(x = lon, y = lat, label = name),
      size               = 2,
      box.padding        = 0.3,
      point.padding      = 0.2,
      nudge_y            = 0.13,
      nudge_x            = 0.4,    # slight right
      segment.color      = "grey20",
      min.segment.length = 0
    ) +
    
    # Scale bar (bottom-right) + north arrow (top-right)
    
    annotation_scale(
      location   = "br",
      width_hint = 0.3
    ) +
    annotation_north_arrow(
      location    = "tr",
      which_north = "true",
      pad_x       = unit(0.4, "cm"),
      pad_y       = unit(0.2, "cm"),
      style       = north_arrow_fancy_orienteering
    ) +
    
    # Titles
    labs(
      title    = "Cumberland River Upstream of Nashville (USGS 03431500)",
      subtitle = "Upstream watershed, main-stem flowlines, and rainfall stations",
      x        = "Longitude",
      y        = "Latitude",
      color    = "Rainfall Station"
    ) +
    
    # Slightly extend x/y so nothing hugs the frame
    coord_sf(
      xlim   = c(-87.8, -82),
      ylim   = c(35, 38),
      expand = FALSE
    ) +
    
    # Simple theme + ticks
    theme_minimal(base_size = 12) +
    theme(
      panel.grid.major  = element_line(color = "grey90", linewidth = 0.3),
      panel.grid.minor  = element_blank(),
      panel.background  = element_rect(fill = "aliceblue", color = NA),
      plot.title        = element_text(face = "bold", size = 14),
      plot.subtitle     = element_text(size = 11),
      legend.position   = "right",
      legend.title      = element_text(face = "bold"),
      axis.ticks        = element_line(color = "grey40"),
      axis.ticks.length = unit(3, "pt"),
      panel.border      = element_rect(color = "black", fill = NA, linewidth = 0.6)
    )
})


ggsave(
  filename = "figures/cumberland_basin_rainfall_stations.png",
  plot     = gg_mrb_map,
  width    = 8,
  height   = 6,
  dpi      = 300
)

