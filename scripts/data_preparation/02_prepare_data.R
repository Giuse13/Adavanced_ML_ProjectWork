source("project/config.R")
paths <- project_paths

raw_data_path <- paths$raw_data_path
processed_data_path <- paths$processed_data_path

if (!file.exists(raw_data_path)) {
  stop("Dataset non trovato in: ", raw_data_path)
}

data <- read.csv(raw_data_path)

# Placeholder per pulizia dati e feature engineering.
prepared_data <- data

write.csv(prepared_data, processed_data_path, row.names = FALSE)
cat("Dataset processato salvato in:", processed_data_path, "\n")
