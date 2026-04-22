processed_data_path <- "data/processed/diabetes_prepared.csv"
model_output_path <- "models/baseline_model.rds"

if (!file.exists(processed_data_path)) {
  stop("Dataset processato non trovato in: ", processed_data_path)
}

data <- read.csv(processed_data_path)

# Placeholder per addestramento modello baseline.
model_info <- list(
  model_name = "baseline_placeholder",
  rows = nrow(data),
  columns = ncol(data)
)

saveRDS(model_info, model_output_path)
cat("Modello baseline salvato in:", model_output_path, "\n")
