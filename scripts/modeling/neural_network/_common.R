library(torch)
library(luz)

target_variable <- "Diabetes_binary"

# Griglia condivisa dagli script validation.R dei tre scenari Neural Network.
default_neural_network_grid <- data.frame(
  hidden_units = c("32", "64", "64-32", "128-64", "32", "64", "64-32", "128-64", "64", "64-32"),
  dropout = c(0, 0, 0.2, 0.2, 0.2, 0.2, 0.4, 0.4, 0.2, 0.2),
  learning_rate = c(0.001, 0.001, 0.001, 0.001, 0.0005, 0.0005, 0.001, 0.0005, 0.001, 0.0005),
  batch_size = rep(128, 10),
  epochs = rep(50, 10),
  weight_decay = c(0, 0, 0, 0, 0, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001),
  stringsAsFactors = FALSE
)

neural_network_module <- nn_module(
  initialize = function(input_size, hidden_units, dropout) {
    layers <- list()
    current_size <- input_size

    for (hidden_size in hidden_units) {
      layers <- append(
        layers,
        list(
          nn_linear(current_size, hidden_size),
          nn_relu()
        )
      )

      if (dropout > 0) {
        layers <- append(layers, list(nn_dropout(p = dropout)))
      }

      current_size <- hidden_size
    }

    layers <- append(layers, list(nn_linear(current_size, 1)))
    self$model <- do.call(nn_sequential, layers)
  },
  forward = function(x) {
    self$model(x)
  }
)

ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
}

log_progress <- function(...) {
  cat(format(Sys.time(), "%H:%M:%S"), "-", ..., "\n")
  flush.console()
}

load_dataset <- function(path) {
  if (!file.exists(path)) {
    stop("Dataset non trovato in: ", path)
  }

  read.csv(path, stringsAsFactors = TRUE)
}

parse_hidden_units <- function(hidden_units) {
  as.integer(strsplit(as.character(hidden_units), "-", fixed = TRUE)[[1]])
}

prepare_neural_network_xy <- function(data, target = target_variable) {
  if (!(target %in% names(data))) {
    stop("Variabile target non trovata: ", target)
  }

  y <- as.numeric(as.character(data[[target]]))
  x <- data[, setdiff(names(data), target), drop = FALSE]

  list(x = x, y = y)
}

build_design_matrices <- function(train_x, test_x = NULL) {
  if (is.null(test_x)) {
    train_matrix <- model.matrix(~ . - 1, data = train_x)

    return(list(
      train = train_matrix,
      test = NULL,
      columns = colnames(train_matrix)
    ))
  }

  train_rows <- nrow(train_x)
  all_x <- rbind(train_x, test_x)
  all_matrix <- model.matrix(~ . - 1, data = all_x)

  list(
    train = all_matrix[seq_len(train_rows), , drop = FALSE],
    test = all_matrix[-seq_len(train_rows), , drop = FALSE],
    columns = colnames(all_matrix)
  )
}

fit_scaler <- function(x) {
  center <- colMeans(x)
  scale <- apply(x, 2, stats::sd)
  scale[is.na(scale) | scale == 0] <- 1

  list(center = center, scale = scale)
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

get_torch_device_name <- function() {
  if (cuda_is_available()) {
    return("cuda")
  }

  "cpu"
}

get_luz_accelerator <- function() {
  accelerator(cpu = !cuda_is_available())
}

accuracy_metric <- function(actual, predicted_score, threshold = 0.5) {
  predicted_probability <- pmin(pmax(predicted_score, 0), 1)
  predicted_class <- as.integer(predicted_probability >= threshold)

  data.frame(
    accuracy = mean(actual == predicted_class)
  )
}

fit_neural_network <- function(x_train, y_train, params, seed) {
  set.seed(seed)
  torch_manual_seed(seed)

  train_dataset <- make_tensor_dataset(x_train, y_train)
  training_device <- get_torch_device_name()

  log_progress("Training Neural Network su device:", training_device)

  neural_network_module %>%
    setup(
      loss = nn_bce_with_logits_loss(),
      optimizer = optim_adam
    ) %>%
    set_hparams(
      input_size = ncol(x_train),
      hidden_units = parse_hidden_units(params$hidden_units),
      dropout = params$dropout
    ) %>%
    set_opt_hparams(
      lr = params$learning_rate,
      weight_decay = params$weight_decay
    ) %>%
    fit(
      data = train_dataset,
      epochs = params$epochs,
      accelerator = get_luz_accelerator(),
      verbose = TRUE,
      dataloader_options = list(batch_size = params$batch_size)
    )
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

run_neural_network_validation <- function(config, grid = default_neural_network_grid, seed = 123) {
  ensure_dir(config$reports_dir)

  log_progress("Avvio validation Neural Network:", config$selection_name)
  log_progress("Training set:", normalizePath(config$training_path, winslash = "/", mustWork = FALSE))
  log_progress("Validation set:", normalizePath(config$validation_path, winslash = "/", mustWork = FALSE))

  training_data <- load_dataset(config$training_path)
  validation_data <- load_dataset(config$validation_path)

  log_progress(
    "Dataset caricati - righe training:",
    nrow(training_data),
    "| righe validation:",
    nrow(validation_data)
  )

  training_xy <- prepare_neural_network_xy(training_data)
  validation_xy <- prepare_neural_network_xy(validation_data)
  design <- build_design_matrices(training_xy$x, validation_xy$x)
  scaler <- fit_scaler(design$train)

  x_train <- apply_scaler(design$train, scaler)
  x_validation <- apply_scaler(design$test, scaler)
  results <- data.frame()

  log_progress(
    "Preprocessing completato - predittori dopo model.matrix:",
    ncol(x_train),
    "| combinazioni da provare:",
    nrow(grid)
  )

  for (i in seq_len(nrow(grid))) {
    params <- grid[i, ]
    log_progress(
      "Validazione Neural Network",
      config$selection_name,
      "- combinazione",
      i,
      "di",
      nrow(grid),
      "| params:",
      paste(names(params), as.character(params[1, ]), sep = "=", collapse = ", ")
    )

    model <- fit_neural_network(
      x_train = x_train,
      y_train = training_xy$y,
      params = params,
      seed = seed + i
    )

    metrics <- accuracy_metric(
      actual = validation_xy$y,
      predicted_score = predict_neural_network_probability(model, x_validation)
    )

    log_progress(
      "Combinazione",
      i,
      "completata - accuracy validation:",
      round(metrics$accuracy, 4)
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
  write.csv(results[1, ], config$best_params_path, row.names = FALSE)

  log_progress(
    "Risultati validazione salvati in:",
    normalizePath(config$validation_results_path, winslash = "/", mustWork = FALSE)
  )
  log_progress(
    "Migliori parametri salvati in:",
    normalizePath(config$best_params_path, winslash = "/", mustWork = FALSE)
  )
  log_progress("Validation Neural Network completata:", config$selection_name)

  results
}

get_best_neural_network_params <- function(best_params_path) {
  if (!file.exists(best_params_path)) {
    stop(
      "Migliori parametri non trovati in: ",
      best_params_path,
      ". Esegui prima la validazione o fornisci un CSV di best params valido."
    )
  }

  best_params <- read.csv(best_params_path, stringsAsFactors = FALSE)
  required_columns <- c(
    "hidden_units",
    "dropout",
    "learning_rate",
    "batch_size",
    "epochs",
    "weight_decay"
  )
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

  params <- best_params[1, required_columns, drop = FALSE]
  params$dropout <- as.numeric(params$dropout)
  params$learning_rate <- as.numeric(params$learning_rate)
  params$batch_size <- as.integer(params$batch_size)
  params$epochs <- as.integer(params$epochs)
  params$weight_decay <- as.numeric(params$weight_decay)
  params
}

train_final_neural_network_model <- function(config, seed = 123) {
  ensure_dir(config$model_dir)

  full_training_data <- load_dataset(config$full_training_path)
  full_training_xy <- prepare_neural_network_xy(full_training_data)
  design <- build_design_matrices(full_training_xy$x)
  scaler <- fit_scaler(design$train)
  x_train <- apply_scaler(design$train, scaler)
  best_params <- get_best_neural_network_params(config$best_params_path)

  cat(
    "Addestramento Neural Network finale",
    config$selection_name,
    "con parametri:",
    paste(names(best_params), as.character(best_params[1, ]), sep = "=", collapse = ", "),
    "\n"
  )

  model <- fit_neural_network(
    x_train = x_train,
    y_train = full_training_xy$y,
    params = best_params,
    seed = seed
  )

  model_bundle <- list(
    model = model,
    model_type = "neural_network",
    selection = config$selection_name,
    target = target_variable,
    predictor_columns = names(full_training_xy$x),
    design_columns = design$columns,
    scaler = scaler,
    best_params = best_params,
    training_device = get_torch_device_name(),
    trained_at = Sys.time()
  )

  model_luz_path <- paste0(config$model_path, ".luz")
  luz_save(model, model_luz_path)

  persisted_model_bundle <- model_bundle
  persisted_model_bundle$model <- NULL
  persisted_model_bundle$model_luz_path <- model_luz_path

  saveRDS(persisted_model_bundle, config$model_path)
  cat(
    "Modello Neural Network salvato in:",
    normalizePath(config$model_path, winslash = "/", mustWork = FALSE),
    "\n"
  )

  model_bundle
}
