required_packages <- c("bnlearn", "Rgraphviz")

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

prepare_tan_data <- function(data, target = target_variable) {
  if (!(target %in% names(data))) {
    stop("Variabile target non trovata: ", target)
  }

  # bnlearn richiede variabili discrete come factor per stimare un TAN discreto.
  data[] <- lapply(data, factor)
  data
}

build_tan_structure <- function(data, target = target_variable) {
  predictors <- setdiff(names(data), target)

  if (length(predictors) < 2) {
    stop("Servono almeno due predittori per addestrare un modello TAN.")
  }

  bnlearn::tree.bayes(
    x = data,
    training = target
  )
}

fit_tan <- function(data, target = target_variable) {
  prepared_data <- prepare_tan_data(data, target = target)
  structure <- build_tan_structure(prepared_data, target = target)

  # method = "bayes" applica smoothing alle tabelle di probabilita' condizionate.
  fitted_model <- bnlearn::bn.fit(
    x = structure,
    data = prepared_data,
    method = "bayes"  #default mle
  )

  list(
    structure = structure,
    fitted_model = fitted_model,
    factor_levels = lapply(prepared_data, levels)
  )
}

save_tan_structure_plot <- function(structure, plot_path) {
  ensure_dir(dirname(plot_path))

  svg(filename = plot_path, width = 18, height = 11.5, bg = "white")
  on.exit(dev.off(), add = TRUE)

  bnlearn::graphviz.plot(
    x = structure,
    layout = "dot",      # layout altenativo usato dalla prof "fdp"
    shape = "ellipse",
    main = "Tree-Augmented Naive Bayes"
  )
}

train_final_tan_model <- function(config) {
  ensure_dir(config$model_dir)
  ensure_dir(config$reports_dir)

  full_training_data <- load_dataset(config$full_training_path)
  trained_model <- fit_tan(full_training_data)

  model_bundle <- list(
    model = trained_model$fitted_model,
    structure = trained_model$structure,
    model_type = "tan",
    selection = config$selection_name,
    target = target_variable,
    predictor_columns = setdiff(names(full_training_data), target_variable),
    factor_levels = trained_model$factor_levels,
    trained_at = Sys.time()
  )

  saveRDS(model_bundle, config$model_path)
  save_tan_structure_plot(
    structure = trained_model$structure,
    plot_path = config$structure_plot_path
  )

  cat(
    "Modello TAN salvato in:",
    normalizePath(config$model_path, winslash = "/", mustWork = FALSE),
    "\n"
  )
  cat(
    "Plot rete TAN salvato in:",
    normalizePath(config$structure_plot_path, winslash = "/", mustWork = FALSE),
    "\n"
  )

  model_bundle
}
