raw_data_path <- "data/raw/diabetes_binary_5050split_health_indicators_BRFSS2015.csv"

if (!file.exists(raw_data_path)) {
  stop("Dataset non trovato in: ", raw_data_path)
}

data <- read.csv(raw_data_path)

cat("Dimensioni dataset:", nrow(data), "righe x", ncol(data), "colonne\n")
cat("Prime colonne:\n")
print(names(data))
cat("\nStruttura:\n")
str(data)
