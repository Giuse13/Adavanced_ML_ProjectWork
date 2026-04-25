required_packages <- c("bnlearn")

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Pacchetti mancanti nell'ambiente del progetto: ",
    paste(missing_packages, collapse = ", ")
  )
}

target_variable <- "Diabetes_binary"

# File unico aggiornato dai tre performance.R.
naive_bayes_evaluation_results_path <- "reports/evaluation/naive_bayes_evaluation.csv"

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

prepare_naive_bayes_test_data <- function(data, factor_levels, target = target_variable) {
  if (!(target %in% names(data))) {
    stop("Variabile target non trovata: ", target)
  }

  missing_columns <- setdiff(names(factor_levels), names(data))
  if (length(missing_columns) > 0) {
    stop(
      "Il test set non contiene le colonne presenti nel training: ",
      paste(missing_columns, collapse = ", ")
    )
  }

  extra_columns <- setdiff(names(data), names(factor_levels))
  if (length(extra_columns) > 0) {
    data <- data[, setdiff(names(data), extra_columns), drop = FALSE]
  }

  # I livelli devono coincidere con quelli osservati in training.
  for (column in names(factor_levels)) {
    data[[column]] <- factor(data[[column]], levels = factor_levels[[column]])
  }

  data[, names(factor_levels), drop = FALSE]
}

accuracy_metric <- function(actual, predicted_class) {
  data.frame(
    accuracy = mean(as.character(actual) == as.character(predicted_class))
  )
}

upsert_naive_bayes_evaluation_result <- function(result, path = naive_bayes_evaluation_results_path) {
  ensure_dir(dirname(path))

  # Aggiorna la riga dello scenario corrente senza duplicarla.
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

run_naive_bayes_test_evaluation <- function(config) {
  if (!file.exists(config$model_path)) {
    stop("Modello Naive Bayes non trovato in: ", config$model_path)
  }

  test_data <- load_dataset(config$test_path)
  model_bundle <- readRDS(config$model_path)

  if (is.null(model_bundle$factor_levels)) {
    stop("Il bundle del modello non contiene factor_levels: ", config$model_path)
  }

  prepared_test_data <- prepare_naive_bayes_test_data(
    data = test_data,
    factor_levels = model_bundle$factor_levels,
    target = model_bundle$target
  )

  predictions <- predict(
    object = model_bundle$model,
    data = prepared_test_data
  )

  metrics <- accuracy_metric(
    actual = prepared_test_data[[model_bundle$target]],
    predicted_class = predictions
  )

  result <- data.frame(
    selection = config$selection_label,
    accuracy = metrics$accuracy,
    stringsAsFactors = FALSE
  )

  results <- upsert_naive_bayes_evaluation_result(result)

  cat("Evaluation Naive Bayes completata per:", config$selection_label, "\n")
  cat("Accuracy test:", round(metrics$accuracy, 4), "\n")
  cat(
    "Risultati salvati in:",
    normalizePath(naive_bayes_evaluation_results_path, winslash = "/", mustWork = FALSE),
    "\n"
  )

  results
}
