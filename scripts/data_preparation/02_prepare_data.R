raw_data_path <- "data/raw/diabetes_binary_5050split_health_indicators_BRFSS2015.csv"
processed_data_path <- "data/processed/diabetes_prepared.csv"

if (!file.exists(raw_data_path)) {
  stop("Dataset non trovato in: ", raw_data_path)
}

data <- read.csv(raw_data_path)

# Placeholder per pulizia dati e feature engineering.
prepared_data <- data

write.csv(prepared_data, processed_data_path, row.names = FALSE)
cat("Dataset processato salvato in:", processed_data_path, "\n")
