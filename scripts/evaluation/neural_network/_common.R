library(torch)
library(luz)

target_variable <- "Diabetes_binary"

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

prepare_neural_network_xy <- function(data, target = target_variable) {
  if (!(target %in% names(data))) {
    stop("Variabile target non trovata: ", target)
  }

  y <- as.numeric(as.character(data[[target]]))
  x <- data[, setdiff(names(data), target), drop = FALSE]

  list(x = x, y = y)
}

build_test_design_matrix <- function(test_x, design_columns) {
  test_matrix <- model.matrix(~ . - 1, data = test_x)
  missing_columns <- setdiff(design_columns, colnames(test_matrix))
  extra_columns <- setdiff(colnames(test_matrix), design_columns)

  # Alcuni livelli categorici presenti in training potrebbero mancare nel test set.
  if (length(missing_columns) > 0) {
    zero_columns <- matrix(
      0,
      nrow = nrow(test_matrix),
      ncol = length(missing_columns),
      dimnames = list(NULL, missing_columns)
    )
    test_matrix <- cbind(test_matrix, zero_columns)
  }

  # Eventuali livelli nuovi nel test non erano noti al modello e vengono rimossi.
  if (length(extra_columns) > 0) {
    test_matrix <- test_matrix[, setdiff(colnames(test_matrix), extra_columns), drop = FALSE]
  }

  # L'ordine delle colonne deve coincidere con quello usato durante il training.
  test_matrix[, design_columns, drop = FALSE]
}

apply_scaler <- function(x, scaler) {
  scaled <- sweep(x, 2, scaler$center, FUN = "-")
  sweep(scaled, 2, scaler$scale, FUN = "/")
}

make_tensor_dataset <- function(x, y) {
  tensor_dataset(
    torch_tensor(x, dtype = torch_float()),
    torch_tensor(matrix(y, ncol = 1), dtype = torch_float())
  )
}

get_luz_accelerator <- function() {
  accelerator(cpu = !cuda_is_available())
}

predict_neural_network_probability <- function(model, x) {
  prediction <- predict(
    model,
    make_tensor_dataset(x, rep(0, nrow(x))),
    accelerator = get_luz_accelerator()
  )

  logits <- as.numeric(as_array(prediction))
  as.numeric(1 / (1 + exp(-logits)))
}

load_neural_network_model <- function(model_bundle, model_path) {
  model_luz_path <- model_bundle$model_luz_path

  if (is.null(model_luz_path)) {
    model_luz_path <- paste0(model_path, ".luz")
  }

  if (file.exists(model_luz_path)) {
    return(luz_load(model_luz_path))
  }

  if (!is.null(model_bundle$model)) {
    return(model_bundle$model)
  }

  stop(
    "File modello Luz non trovato: ",
    model_luz_path,
    ". Riesegui lo script di training della rete neurale per salvare il modello con luz_save()."
  )
}

accuracy_metric <- function(actual, predicted_score, threshold = 0.5) {
  predicted_probability <- pmin(pmax(predicted_score, 0), 1)
  predicted_class <- as.integer(predicted_probability >= threshold)

  data.frame(
    accuracy = mean(actual == predicted_class)
  )
}

upsert_neural_network_evaluation_result <- function(result, path) {
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

run_neural_network_test_evaluation <- function(config) {
  if (!file.exists(config$model_path)) {
    stop("Modello Neural Network non trovato in: ", config$model_path)
  }

  test_data <- load_dataset(config$test_path)
  test_xy <- prepare_neural_network_xy(test_data)
  model_bundle <- readRDS(config$model_path)

  if (is.null(model_bundle$design_columns)) {
    stop("Il bundle del modello non contiene design_columns: ", config$model_path)
  }

  if (is.null(model_bundle$scaler)) {
    stop("Il bundle del modello non contiene scaler: ", config$model_path)
  }

  test_matrix <- build_test_design_matrix(
    test_x = test_xy$x,
    design_columns = model_bundle$design_columns
  )
  x_test <- apply_scaler(test_matrix, model_bundle$scaler)
  model <- load_neural_network_model(model_bundle, config$model_path)

  metrics <- accuracy_metric(
    actual = test_xy$y,
    predicted_score = predict_neural_network_probability(model, x_test)
  )

  result <- data.frame(
    selection = config$selection_label,
    accuracy = metrics$accuracy,
    stringsAsFactors = FALSE
  )

  results <- upsert_neural_network_evaluation_result(result, config$evaluation_results_path)

  cat("Evaluation Neural Network completata per:", config$selection_label, "\n")
  cat("Accuracy test:", round(metrics$accuracy, 4), "\n")
  cat(
    "Risultati salvati in:",
    normalizePath(config$evaluation_results_path, winslash = "/", mustWork = FALSE),
    "\n"
  )

  results
}
