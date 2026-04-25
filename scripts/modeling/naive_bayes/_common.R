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

prepare_naive_bayes_data <- function(data, target = target_variable) {
  if (!(target %in% names(data))) {
    stop("Variabile target non trovata: ", target)
  }

  # bnlearn richiede variabili discrete come factor per stimare un Naive Bayes discreto.
  data[] <- lapply(data, factor)
  data
}

build_naive_bayes_structure <- function(data, target = target_variable) {
  predictors <- setdiff(names(data), target)

  if (length(predictors) < 1) {
    stop("Nessun predittore disponibile per il modello Naive Bayes.")
  }

  bnlearn::naive.bayes(
    x = data,
    training = target
  )
}

fit_naive_bayes <- function(data, target = target_variable) {
  prepared_data <- prepare_naive_bayes_data(data, target = target)
  structure <- build_naive_bayes_structure(prepared_data, target = target)

  # method = "bayes" applica smoothing alle tabelle di probabilita' condizionate.
  fitted_model <- bnlearn::bn.fit(
    x = structure,
    data = prepared_data,
    method = "bayes"
  )

  list(
    structure = structure,
    fitted_model = fitted_model,
    factor_levels = lapply(prepared_data, levels)
  )
}

train_final_naive_bayes_model <- function(config) {
  ensure_dir(config$model_dir)

  full_training_data <- load_dataset(config$full_training_path)
  trained_model <- fit_naive_bayes(full_training_data)

  model_bundle <- list(
    model = trained_model$fitted_model,
    structure = trained_model$structure,
    model_type = "naive_bayes",
    selection = config$selection_name,
    target = target_variable,
    predictor_columns = setdiff(names(full_training_data), target_variable),
    factor_levels = trained_model$factor_levels,
    trained_at = Sys.time()
  )

  saveRDS(model_bundle, config$model_path)
  cat(
    "Modello Naive Bayes salvato in:",
    normalizePath(config$model_path, winslash = "/", mustWork = FALSE),
    "\n"
  )

  model_bundle
}
