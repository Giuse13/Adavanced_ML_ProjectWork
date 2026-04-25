library(BART)

target_variable <- "Diabetes_binary"
bart_evaluation_results_path <- "reports/evaluation/bart_evaluation.csv"

ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
}

load_dataset <- function(path) {
  if (!file.exists(path)) {
    stop("Dataset non trovato in: ", path)
  }

  read.csv(path, stringsAsFactors = TRUE)
}

prepare_bart_xy <- function(data, target = target_variable) {
  if (!(target %in% names(data))) {
    stop("Variabile target non trovata: ", target)
  }

  y <- as.numeric(as.character(data[[target]]))
  x <- data[, setdiff(names(data), target), drop = FALSE]

  list(x = x, y = y)
}

accuracy_metric <- function(actual, predicted_score, threshold = 0.5) {
  predicted_probability <- pmin(pmax(predicted_score, 0), 1)
  predicted_class <- as.integer(predicted_probability >= threshold)

  data.frame(
    accuracy = mean(actual == predicted_class)
  )
}

get_bart_predictions <- function(model, validation = TRUE) {
  if (validation && !is.null(model$prob.test.mean)) {
    return(model$prob.test.mean)
  }

  if (validation && !is.null(model$yhat.test.mean)) {
    return(model$yhat.test.mean)
  }

  if (!validation && !is.null(model$prob.train.mean)) {
    return(model$prob.train.mean)
  }

  if (!validation && !is.null(model$yhat.train.mean)) {
    return(model$yhat.train.mean)
  }

  stop("Predizioni non trovate nell'oggetto BART.")
}

build_test_design_matrix <- function(test_x, design_columns) {
  test_matrix <- model.matrix(~ . - 1, data = test_x)
  missing_columns <- setdiff(design_columns, colnames(test_matrix))
  extra_columns <- setdiff(colnames(test_matrix), design_columns)

  if (length(missing_columns) > 0) {
    zero_columns <- matrix(
      0,
      nrow = nrow(test_matrix),
      ncol = length(missing_columns),
      dimnames = list(NULL, missing_columns)
    )
    test_matrix <- cbind(test_matrix, zero_columns)
  }

  if (length(extra_columns) > 0) {
    test_matrix <- test_matrix[, setdiff(colnames(test_matrix), extra_columns), drop = FALSE]
  }

  test_matrix[, design_columns, drop = FALSE]
}

upsert_bart_evaluation_result <- function(result, path = bart_evaluation_results_path) {
  ensure_dir(dirname(path))

  if (file.exists(path)) {
    results <- read.csv(path, stringsAsFactors = FALSE)
    results <- results[results$selection != result$selection, , drop = FALSE]
    results <- rbind(results, result)
  } else {
    results <- result
  }

  selection_order <- c(
    "no variable selection",
    "aic variable selection",
    "bic variable selection"
  )
  results$selection <- factor(results$selection, levels = selection_order)
  results <- results[order(results$selection), , drop = FALSE]
  results$selection <- as.character(results$selection)

  write.csv(results, path, row.names = FALSE)
  results
}

get_bart_evaluation_predictions <- function(prediction) {
  if (is.numeric(prediction)) {
    return(prediction)
  }

  get_bart_predictions(prediction, validation = TRUE)
}

run_bart_test_evaluation <- function(config) {
  if (!file.exists(config$model_path)) {
    stop("Modello BART non trovato in: ", config$model_path)
  }

  test_data <- load_dataset(config$test_path)
  test_xy <- prepare_bart_xy(test_data)
  model_bundle <- readRDS(config$model_path)

  if (is.null(model_bundle$design_columns)) {
    stop("Il bundle del modello non contiene design_columns: ", config$model_path)
  }

  test_matrix <- build_test_design_matrix(
    test_x = test_xy$x,
    design_columns = model_bundle$design_columns
  )

  prediction <- predict(model_bundle$model, test_matrix)
  metrics <- accuracy_metric(
    actual = test_xy$y,
    predicted_score = get_bart_evaluation_predictions(prediction)
  )

  result <- data.frame(
    selection = config$selection_label,
    accuracy = metrics$accuracy,
    stringsAsFactors = FALSE
  )

  results <- upsert_bart_evaluation_result(result)

  cat("Evaluation BART completata per:", config$selection_label, "\n")
  cat("Accuracy test:", round(metrics$accuracy, 4), "\n")
  cat(
    "Risultati salvati in:",
    normalizePath(bart_evaluation_results_path, winslash = "/", mustWork = FALSE),
    "\n"
  )

  results
}
