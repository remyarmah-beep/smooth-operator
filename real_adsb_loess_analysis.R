# ==============================================================================
# 1. PARSING THE KML FILE
# ==============================================================================

# Read the file
raw_text <- readLines("track.kml", warn = FALSE)

times_lines  <- raw_text[grepl("<when", raw_text)]
coords_lines <- raw_text[grepl("<gx:coord", raw_text)]

times_raw  <- gsub(".*<when[^>]*>(.*?)</when>.*", "\\1", times_lines)
coords_raw <- gsub(".*<gx:coord[^>]*>(.*?)</gx:coord>.*", "\\1", coords_lines)

min_len <- min(length(times_raw), length(coords_raw))
coord_list <- strsplit(coords_raw[1:min_len], " ")

trajectory_df <- data.frame(
  time_step = seq_len(min_len),
  lon = as.numeric(sapply(coord_list, `[`, 1)),
  lat = as.numeric(sapply(coord_list, `[`, 2)),
  alt = as.numeric(sapply(coord_list, `[`, 3))
)

# ==============================================================================
# 2. FIT NON-PARAMETRIC LOESS MODELS & EXTRACT RESIDUALS
# ==============================================================================
span_val <- 0.12 # Tightened slightly to capture runway turn geometry

loess_lon <- loess(lon ~ time_step, data = trajectory_df, span = span_val)
loess_lat <- loess(lat ~ time_step, data = trajectory_df, span = span_val)
loess_alt <- loess(alt ~ time_step, data = trajectory_df, span = span_val)

trajectory_df$smooth_lon <- predict(loess_lon)
trajectory_df$smooth_lat <- predict(loess_lat)
trajectory_df$smooth_alt <- predict(loess_alt)

# Calculate Altimeter Residuals: e_t = Observed - Smoothed
trajectory_df$alt_residual <- trajectory_df$alt - trajectory_df$smooth_alt

# ==============================================================================
# 3. 4-PANEL DIAGNOSTIC DASHBOARD (2x2 GRID)
# ==============================================================================
par(mfrow = c(2, 2), mar = c(4.2, 4.2, 3, 1.5))

# PANEL 1: Macro 2D Ground Track
plot(trajectory_df$lon, trajectory_df$lat, col = "darkgray", pch = 16, cex = 0.7,
     main = "1. Macro 2D Flight Path (EDDF Departure)",
     xlab = "Longitude (°E)", ylab = "Latitude (°N)")
lines(trajectory_df$smooth_lon, trajectory_df$smooth_lat, col = "red", lwd = 2.5)
legend("bottomright", legend = c("Raw ADS-B", "LOESS Path"),
       col = c("darkgray", "red"), pch = c(16, NA), lty = c(NA, 1), lwd = c(NA, 2.5), cex = 0.75)

# PANEL 2: Macro Altitude Climb Profile
plot(trajectory_df$time_step, trajectory_df$alt, col = "darkgray", pch = 16, cex = 0.7,
     main = "2. Vertical Profile (Taxi, Climb & TOC)",
     xlab = "Time Step (index)", ylab = "Geometric Altitude (m)")
lines(trajectory_df$time_step, trajectory_df$smooth_alt, col = "blue", lwd = 2.5)
legend("bottomright", legend = c("Raw GPS Alt", "LOESS Smooth"),
       col = c("darkgray", "blue"), pch = c(16, NA), lty = c(NA, 1), lwd = c(NA, 2.5), cex = 0.75)

# PANEL 3: Micro-Zoom on Frankfurt Runway 18 Turn & Rotation (Steps 90 to 165)
zoom_df <- trajectory_df[90:165, ]
plot(zoom_df$lon, zoom_df$lat, col = "darkgray", pch = 16, cex = 1.1,
     main = "3. Zoom: Runway 18 Lineup & Takeoff Roll",
     xlab = "Longitude (°E)", ylab = "Latitude (°N)")
lines(zoom_df$smooth_lon, zoom_df$smooth_lat, col = "red", lwd = 3)
legend("topright", legend = c("Quantized GPS Steps", "Continuous LOESS"),
       col = c("darkgray", "red"), pch = c(16, NA), lty = c(NA, 1), lwd = c(NA, 3), cex = 0.75)

# PANEL 4: Altimeter Signal Residuals (Noise & Phase Transition Spikes)
plot(trajectory_df$time_step, trajectory_df$alt_residual, type = "h", col = "darkorange", lwd = 1.5,
     main = "4. Altimeter Residuals (Observed - LOESS)",
     xlab = "Time Step (index)", ylab = "Residual Error (m)")
abline(h = 0, col = "black", lty = 2, lwd = 1.5)

par(mfrow = c(1, 1))
