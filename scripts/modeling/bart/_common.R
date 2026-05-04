library(BART)

target_variable <- "Diabetes_binary"

# Griglia condivisa dagli script validation.R dei tre scenari BART.
default_bart_grid <- expand.grid(
  ntree = c(100, 200, 300),
  k = c(2),
  power = c(2),
  base = c(0.95),
  ndpost = 1000,
  nskip = 100
)

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

build_design_matrices <- function(train_x, test_x = NULL) {
  if (is.null(test_x)) {
    # model.matrix trasforma factor e categoriche nelle stesse dummy usate da BART.
    train_matrix <- model.matrix(~ . - 1, data = train_x)

    return(list(
      train = train_matrix,
      test = NULL,
      columns = colnames(train_matrix)
    ))
  }

  # Costruire train e test insieme garantisce la stessa codifica delle variabili categoriche.
  train_rows <- nrow(train_x)
  all_x <- rbind(train_x, test_x)
  all_matrix <- model.matrix(~ . - 1, data = all_x)

  list(
    train = all_matrix[seq_len(train_rows), , drop = FALSE],
    test = all_matrix[-seq_len(train_rows), , drop = FALSE],
    columns = colnames(all_matrix)
  )
}

accuracy_metric <- function(actual, predicted_score, threshold = 0.5) {
  predicted_probability <- pmin(pmax(predicted_score, 0), 1)
  predicted_class <- as.integer(predicted_probability >= threshold)

  data.frame(
    accuracy = mean(actual == predicted_class)
  )
}

get_bart_mc_cores <- function() {
  configured_cores <- Sys.getenv("BART_MC_CORES", unset = "")

  if (nzchar(configured_cores)) {
    parsed_cores <- suppressWarnings(as.integer(configured_cores))

    if (!is.na(parsed_cores) && parsed_cores >= 1) {
      return(parsed_cores)
    }

    warning("BART_MC_CORES non valido: ", configured_cores, ". Uso mc.cores = 1.")
  }

  1L
}

fit_gbart <- function(x_train, y_train, x_test = NULL, params, seed) {
  set.seed(seed)
  mc_cores <- get_bart_mc_cores()

  # type = "pbart" usa BART per classificazione binaria con output probabilistico.
  args <- list(
    x.train = x_train,
    y.train = y_train,
    type = "pbart",
    ntree = params$ntree,
    k = params$k,
    power = params$power,
    base = params$base,
    ndpost = params$ndpost,
    nskip = params$nskip,
    keepevery = 1,
    seed = seed,
    printevery = 100,
    mc.cores = mc_cores
  )

  if (!is.null(x_test)) {
    args$x.test <- x_test
  }

  cat("BART mc.cores =", mc_cores, "\n")

  do.call(gbart, args)
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

run_bart_validation <- function(config, grid = default_bart_grid, seed = 123) {
  ensure_dir(config$reports_dir)

  # La validazione usa training e validation separati per scegliere gli iperparametri.
  training_data <- load_dataset(config$training_path)
  validation_data <- load_dataset(config$validation_path)

  training_xy <- prepare_bart_xy(training_data)
  validation_xy <- prepare_bart_xy(validation_data)
  design <- build_design_matrices(training_xy$x, validation_xy$x)

  results <- data.frame()

  for (i in seq_len(nrow(grid))) {
    params <- grid[i, ]
    cat("Validazione BART", config$selection_name, "- combinazione", i, "di", nrow(grid), "\n")

    model <- fit_gbart(
      x_train = design$train,
      y_train = training_xy$y,
      x_test = design$test,
      params = params,
      seed = seed + i
    )

    metrics <- accuracy_metric(
      actual = validation_xy$y,
      predicted_score = get_bart_predictions(model, validation = TRUE)
    )

    results <- rbind(
      results,
      cbind(
        selection = config$selection_name,
        params,
        metrics,
        stringsAsFactors = FALSE
      )
    )
  }

  results <- results[order(-results$accuracy), ]
  write.csv(results, config$validation_results_path, row.names = FALSE)

  # Il training finale legge solo questa riga: deve contenere i parametri migliori.
  write.csv(results[1, ], config$best_params_path, row.names = FALSE)

  cat(
    "Risultati validazione salvati in:",
    normalizePath(config$validation_results_path, winslash = "/", mustWork = FALSE),
    "\n"
  )
  cat(
    "Migliori parametri salvati in:",
    normalizePath(config$best_params_path, winslash = "/", mustWork = FALSE),
    "\n"
  )
  results
}

get_best_bart_params <- function(best_params_path) {
  if (!file.exists(best_params_path)) {
    stop(
      "Migliori parametri non trovati in: ",
      best_params_path,
      ". Esegui prima la validazione o fornisci un CSV di best params valido."
    )
  }

  best_params <- read.csv(best_params_path, stringsAsFactors = FALSE)
  required_columns <- c("ntree", "k", "power", "base", "ndpost", "nskip")
  missing_columns <- setdiff(required_columns, names(best_params))

  if (nrow(best_params) < 1) {
    stop("Il file dei migliori parametri e' vuoto: ", best_params_path)
  }

  if (length(missing_columns) > 0) {
    stop(
      "Il file dei migliori parametri non contiene le colonne richieste: ",
      paste(missing_columns, collapse = ", ")
    )
  }

  best_params[1, required_columns, drop = FALSE]
}

train_final_bart_model <- function(config, seed = 123) {
  ensure_dir(config$model_dir)

  # Il modello finale viene addestrato su training + validation usando i best params.
  full_training_data <- load_dataset(config$full_training_path)
  full_training_xy <- prepare_bart_xy(full_training_data)
  design <- build_design_matrices(full_training_xy$x)
  best_params <- get_best_bart_params(config$best_params_path)

  cat(
    "Addestramento BART finale",
    config$selection_name,
    "con parametri:",
    paste(names(best_params), as.character(best_params[1, ]), sep = "=", collapse = ", "),
    "\n"
  )

  model <- fit_gbart(
    x_train = design$train,
    y_train = full_training_xy$y,
    params = best_params,
    seed = seed
  )

  model_bundle <- list(
    model = model,
    model_type = "bart",
    selection = config$selection_name,
    target = target_variable,
    predictor_columns = names(full_training_xy$x),
    # Necessario in evaluation per riallineare le colonne generate da model.matrix.
    design_columns = design$columns,
    best_params = best_params,
    trained_at = Sys.time()
  )

  saveRDS(model_bundle, config$model_path)
  cat(
    "Modello BART salvato in:",
    normalizePath(config$model_path, winslash = "/", mustWork = FALSE),
    "\n"
  )

  model_bundle
}
