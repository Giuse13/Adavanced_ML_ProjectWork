if (!requireNamespace("randomForest", quietly = TRUE)) {
  stop(
    "Pacchetto 'randomForest' non installato. ",
    "Installa con install.packages('randomForest') e rilancia questo script."
  )
}

target <- "Diabetes_binary"
train_path <- "data/processed/aic_selection/full_training_set_aic.csv"
test_path <- "data/processed/aic_selection/test_set_aic.csv"

set.seed(123)

train_data <- read.csv(train_path, stringsAsFactors = TRUE)
test_data <- read.csv(test_path, stringsAsFactors = TRUE)

train_data[[target]] <- factor(train_data[[target]], levels = c(0, 1))
test_data[[target]] <- factor(test_data[[target]], levels = c(0, 1))

rf_formula <- as.formula(paste(target, "~ ."))

rf_model <- randomForest::randomForest(
  formula = rf_formula,
  data = train_data,
  ntree = 200,
  mtry = floor(sqrt(ncol(train_data) - 1)),
  nodesize = 10,
  importance = TRUE
)

predictions <- predict(rf_model, newdata = test_data)
confusion <- table(
  actual = test_data[[target]],
  predicted = predictions
)
accuracy <- mean(predictions == test_data[[target]])

cat("Random Forest baseline su variabili AIC\n")
cat("Training set:", train_path, "\n")
cat("Test set:", test_path, "\n")
cat("Accuracy test:", round(accuracy, 4), "\n\n")
cat("Confusion matrix:\n")
print(confusion)
