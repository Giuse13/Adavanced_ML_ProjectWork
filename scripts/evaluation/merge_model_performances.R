source("project/config.R")

paths <- project_paths

ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
}

read_model_evaluation <- function(model_name, path) {
  if (!file.exists(path)) {
    stop("File di evaluation non trovato per ", model_name, ": ", path)
  }

  evaluation <- read.csv(path, stringsAsFactors = FALSE)
  required_columns <- c("selection", "accuracy")
  missing_columns <- setdiff(required_columns, names(evaluation))

  if (length(missing_columns) > 0) {
    stop(
      "Il file di evaluation per ",
      model_name,
      " non contiene le colonne richieste: ",
      paste(missing_columns, collapse = ", ")
    )
  }

  evaluation$model <- model_name
  evaluation[, c("model", "selection", "accuracy"), drop = FALSE]
}

model_evaluation_paths <- list(
  "BART" = paths$bart_evaluation_results_path,
  "Naive Bayes" = paths$naive_bayes_evaluation_results_path,
  "TAN" = paths$tan_evaluation_results_path,
  "Neural Network" = paths$neural_network_evaluation_results_path
)

selection_order <- c(
  "no variable selection",
  "aic variable selection",
  "bic variable selection"
)

long_results <- do.call(
  rbind,
  Map(read_model_evaluation, names(model_evaluation_paths), model_evaluation_paths)
)

wide_results <- reshape(
  long_results,
  idvar = "model",
  timevar = "selection",
  direction = "wide"
)

expected_columns <- paste0("accuracy.", selection_order)
missing_selection_columns <- setdiff(expected_columns, names(wide_results))

if (length(missing_selection_columns) > 0) {
  for (column in missing_selection_columns) {
    wide_results[[column]] <- NA_real_
  }
}

wide_results <- wide_results[, c("model", expected_columns), drop = FALSE]
names(wide_results) <- c("model", selection_order)

model_order <- names(model_evaluation_paths)
wide_results$model <- factor(wide_results$model, levels = model_order)
wide_results <- wide_results[order(wide_results$model), , drop = FALSE]
wide_results$model <- as.character(wide_results$model)

ensure_dir(dirname(paths$model_comparison_evaluation_results_path))
write.csv(
  wide_results,
  paths$model_comparison_evaluation_results_path,
  row.names = FALSE
)

cat(
  "Confronto performance modelli salvato in:",
  normalizePath(paths$model_comparison_evaluation_results_path, winslash = "/", mustWork = FALSE),
  "\n"
)

wide_results
