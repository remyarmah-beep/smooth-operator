#Impact de la Bande Passante et Effet d'Échelle (KDE)
# 1. Split the RStudio plot window to stack 2 graphs vertically
par(mfrow=c(2,1))
# 2. Simulate Charles de Gaulle (Busy: 100 planes, around 5 mins late)
cdg_data <- rnorm(100, mean=0, sd=5)
# 3. Simulate Poitiers (Quiet: 10 planes, also around 5 mins late)
poitiers_data <- rnorm(10, mean=0, sd=5)
# 4. GRAPH 1 (CDG): Force a fixed bandwidth of 3
plot(density(cdg_data, bw=3),
     main="CDG (100 Planes) - Fixed Bandwidth = 3",
     col="blue", lwd=3, xlab="Minutes Late", xlim=c(-20, 20), ylim=c(0, 0.15))
rug(cdg_data, col="blue", lwd=2)
# 5. GRAPH 2 (Poitiers): Force the EXACT SAME fixed bandwidth of 3
plot(density(poitiers_data, bw=3),
     main="Poitiers (10 Planes) - Fixed Bandwidth = 3",
     col="red", lwd=3, xlab="Minutes Late", xlim=c(-20, 20), ylim=c(0, 0.15))
rug(poitiers_data, col="red", lwd=2)
# 6. Reset the R graphics window
par(mfrow=c(1,1))

#Filtrage de Signal Bruité (RégressionLOESS)
# 1. Simulate Time (1 to 100 seconds)
time_sec <- 1:100
# 2. Simulate True Altitude (A rolling climb maneuver)
true_alt <- 10000 + 500 * sin(time_sec / 15)
# 3. Add Sensor Noise - Standard deviation of 150 feet
noise <- rnorm(100, mean=0, sd=150)
sensor_data <- true_alt + noise
# 4. Plot the messy observed data (The dots)
plot(time_sec, sensor_data, col="darkgray", pch=16,
     main="Altimeter: LOESS Smoothing",
     xlab="Time (seconds)", ylab="Altitude (feet)")
# 5. Apply the LOESS algorithm (span = 0.3)
smoothed_model <- loess(sensor_data ~ time_sec, span=0.3)
# 6. Draw the Nonparametric curve in red
lines(time_sec, predict(smoothed_model), col="red", lwd=3)


#Test Final sur Données Aéronautiques Réalistes (Tours de Piste ATC)
# Set seed for reproducibility
set.seed(42)
# 1. GENERATE THE DATA
# Bimodal distribution: 150 on-time flights, 100 delayed flights
arrival_delay <- c(rnorm(150, mean = 2, sd = 5), rnorm(100, mean = 45, sd = 10))
# Non-linear holding time (Plateaus for delayed due to fuel limits)
holding_time <- ifelse(arrival_delay < 15,
                       rnorm(150, mean = 5, sd = 4),
                       rnorm(100, mean = 35, sd = 6) + 8 * sin(arrival_delay/10))
holding_time[holding_time < 0] <- 0
# Organize the graph window (1 row, 2 columns)
par(mfrow = c(1, 2))
# TASK 1: KDE OF ARRIVAL DELAYS
plot(density(arrival_delay),
     main = "KDE: Density of Arrival Delays",
     xlab = "Minutes Late", col = "blue", lwd = 3)
rug(arrival_delay, col = "red")
# TASK 2: LOESS PREDICTION OF HOLDING PATTERNS
plot(arrival_delay, holding_time,
     main = "LOESS: Predicting Holding Time",
     xlab = "Arrival Delay (minutes)", ylab = "Time in Holding Pattern (minutes)",
     col = "darkgray", pch = 16)
# Linear Model (Blue dashed line)
linear_model <- lm(holding_time ~ arrival_delay)
abline(linear_model, col = "blue", lwd = 2, lty = 2)
# LOESS Model (Red solid line)
loess_model <- loess(holding_time ~ arrival_delay, span = 0.4)
order_x <- order(arrival_delay)
lines(arrival_delay[order_x], predict(loess_model)[order_x], col = "red", lwd = 3)
legend("topleft", legend = c("Parametric (Linear)", "Nonparametric (LOESS)"),
       col = c("blue", "red"), lwd = c(2, 3), lty = c(2, 1), cex=0.8)
par(mfrow = c(1, 1))

#Lissage d'une Trajectoire Spatiale 2D (Radar ATC)
# 1. Génération de la trajectoire réelle (Demi-cercle)
time_sec <- 1:100
true_x <- 500 * cos(time_sec / 20)
true_y <- 500 * sin(time_sec / 20)
# 2. Ajout du bruit radar (Interférence gaussienne)
noise_x <- rnorm(100, mean = 0, sd = 40)
noise_y <- rnorm(100, mean = 0, sd = 40)
radar_x <- true_x + noise_x
radar_y <- true_y + noise_y
# 3. Application LOESS (Découplage temporel indépendant)
span_val <- 0.3
smoothed_x <- predict(loess(radar_x ~ time_sec, span = span_val))
smoothed_y <- predict(loess(radar_y ~ time_sec, span = span_val))
# 4. Rendus graphiques
plot(radar_x, radar_y,
     main = "Radar Tracking: Aircraft Approach Maneuver",
     xlab = "Longitude (X)", ylab = "Latitude (Y)",
     col = "darkgray", pch = 16, cex = 0.8)
lines(true_x, true_y, col = "blue", lwd = 2, lty = 2)
lines(smoothed_x, smoothed_y, col = "red", lwd = 3)
legend("bottomleft",
       legend = c("Raw Radar Data", "True Flight Path", "LOESS Reconstruction"),
       col = c("darkgray", "blue", "red"),
       pch = c(16, NA, NA), lty = c(NA, 2, 1), lwd = c(NA, 2, 3))

#Démonstration Empirique du Fléau de la Dimension
n_flights <- 1000
dimensions <- 1:10
nearest_distances <- numeric(10)
# Calcul des distances euclidiennes dans des espaces de complexité croissante
for(d in dimensions) {
  data_matrix <- matrix(runif(n_flights * d, min = -1, max = 1),
                        nrow = n_flights, ncol = d)
  distances <- sqrt(rowSums(data_matrix^2))
  nearest_distances[d] <- min(distances)
}
# Rendus graphiques
plot(dimensions, nearest_distances, type = "b", col = "red", lwd = 3, pch = 16,
     main = "The Curse of Dimensionality (n = 1000)",
     xlab = "Number of Dimensions (Variables)",
     ylab = "Distance to the CLOSEST neighboring point")
abline(h = nearest_distances[1], col = "blue", lty = 2, lwd = 2)

#Analyse Comparative (Manœuvre d'Évitement)
set.seed(99)
# 1. Génération de la trajectoire complexe (Courbe en S puis vol palier)
time <- 1:150
true_path <- 1000 + 500 * sin(time / 15) * exp(-time / 50) + (time > 100) * 200
noise <- rnorm(150, mean = 0, sd = 100)
observed_alt <- true_path + noise
# 2. Ajustement des modèles
parametric_model <- lm(observed_alt ~ poly(time, 3))
loess_model <- loess(observed_alt ~ time, span = 0.2)
# 3. Rendus graphiques
plot(time, observed_alt, col = "darkgray", pch = 16, cex = 0.8,
main = "Comparative Analysis: Evasion Maneuver",
xlab = "Time (seconds)", ylab = "Altitude (feet)")
lines(time, true_path, col = "black", lwd = 2, lty = 2)
lines(time, predict(parametric_model), col = "blue", lwd = 3)
lines(time, predict(loess_model), col = "red", lwd = 3)
legend("topright",
legend = c("Observed Data", "True Path", "Parametric (Polynomial)", "Nonparametric
(LOESS)"),
col = c("darkgray", "black", "blue", "red"),
pch = c(16, NA, NA, NA), lty = c(NA, 2, 1, 1), lwd = c(NA, 2, 3, 3))
