source("project/config.R")

paths <- project_paths

required_packages <- c("ggplot2", "patchwork", "ragg", "systemfonts")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop("Pacchetti R mancanti: ", paste(missing_packages, collapse = ", "))
}

library(ggplot2)
library(patchwork)

slides_dir <- "slides"
slides_data_dir <- file.path(slides_dir, "data")
slides_figures_dir <- file.path(slides_dir, "figures")
slides_fonts_dir <- file.path(slides_dir, "fonts")

plot_output_path <- file.path(slides_figures_dir, "model_results_accuracy_confusion.png")
confusion_output_path <- file.path(slides_data_dir, "best_models_confusion_matrices.csv")

if (!file.exists(paths$model_comparison_evaluation_results_path)) {
  stop("File accuracy non trovato: ", paths$model_comparison_evaluation_results_path)
}

dir.create(slides_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(slides_figures_dir, recursive = TRUE, showWarnings = FALSE)

background_color <- "#fbf6f1"
primary_color <- "#20b48c"
secondary_color <- "#a9dfd0"
accent_color <- "#0f6d58"
muted_color <- "#efe4dc"
grid_color <- "#ddd5ce"
text_color <- "#000000"
font_family <- "Raleway"
slide_width_px <- 1920
slide_height_px <- 1080
slide_dpi <- 160
target_variable <- "Diabetes_binary"

local_raleway_medium <- file.path(slides_fonts_dir, "Raleway", "static", "Raleway-Medium.ttf")
local_raleway_bold <- file.path(slides_fonts_dir, "Raleway", "static", "Raleway-Bold.ttf")

if (file.exists(local_raleway_medium) && file.exists(local_raleway_bold)) {
  systemfonts::register_font(
    name = font_family,
    plain = local_raleway_medium,
    bold = local_raleway_bold,
    italic = local_raleway_medium,
    bolditalic = local_raleway_bold
  )
} else {
  warning(
    "Font richiesti non trovati: ",
    local_raleway_medium,
    " / ",
    local_raleway_bold,
    ". Il device grafico usera' un fallback."
  )
}

selection_levels <- c(
  "no variable selection",
  "aic variable selection",
  "bic variable selection"
)

selection_labels <- c(
  "no variable selection" = "No selection",
  "aic variable selection" = "AIC MB",
  "bic variable selection" = "BIC MB"
)

model_levels <- c("BART", "Neural Network", "Naive Bayes", "TAN")

model_labels <- c(
  "BART" = "BART",
  "Neural Network" = "Rete neurale",
  "Naive Bayes" = "Naive Bayes",
  "TAN" = "TAN"
)

scenario_paths <- list(
  "no variable selection" = list(
    test_path = paths$test_set_path,
    bart_model_path = paths$bart_no_selection_model_path,
    neural_network_model_path = paths$neural_network_no_selection_model_path,
    naive_bayes_model_path = paths$naive_bayes_no_selection_model_path,
    tan_model_path = paths$tan_no_selection_model_path
  ),
  "aic variable selection" = list(
    test_path = paths$aic_test_set_path,
    bart_model_path = paths$bart_aic_selection_model_path,
    neural_network_model_path = paths$neural_network_aic_selection_model_path,
    naive_bayes_model_path = paths$naive_bayes_aic_selection_model_path,
    tan_model_path = paths$tan_aic_selection_model_path
  ),
  "bic variable selection" = list(
    test_path = paths$bic_test_set_path,
    bart_model_path = paths$bart_bic_selection_model_path,
    neural_network_model_path = paths$neural_network_bic_selection_model_path,
    naive_bayes_model_path = paths$naive_bayes_bic_selection_model_path,
    tan_model_path = paths$tan_bic_selection_model_path
  )
)

read_accuracy_data <- function(path) {
  wide_data <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  long_data <- data.frame(
    model = character(),
    selection = character(),
    accuracy = numeric(),
    stringsAsFactors = FALSE
  )

  for (selection in selection_levels) {
    long_data <- rbind(
      long_data,
      data.frame(
        model = wide_data$model,
        selection = selection,
        accuracy = wide_data[[selection]],
        stringsAsFactors = FALSE
      )
    )
  }

  long_data$model <- factor(long_data$model, levels = rev(model_levels))
  long_data$selection <- factor(long_data$selection, levels = selection_levels)
  long_data$model_label <- model_labels[as.character(long_data$model)]
  long_data$selection_label <- selection_labels[as.character(long_data$selection)]
  long_data$accuracy_label <- sprintf("%.2f%%", 100 * long_data$accuracy)
  long_data
}

get_best_scenarios <- function(accuracy_data) {
  best_rows <- do.call(
    rbind,
    lapply(model_levels, function(model_name) {
      model_data <- accuracy_data[as.character(accuracy_data$model) == model_name, ]
      model_data <- model_data[order(-model_data$accuracy), ]
      model_data[1, , drop = FALSE]
    })
  )

  best_rows$model <- as.character(best_rows$model)
  best_rows$selection <- as.character(best_rows$selection)
  best_rows
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

apply_scaler <- function(x, scaler) {
  scaled <- sweep(x, 2, scaler$center, FUN = "-")
  sweep(scaled, 2, scaler$scale, FUN = "/")
}

prepare_factor_test_data <- function(data, factor_levels) {
  missing_columns <- setdiff(names(factor_levels), names(data))
  if (length(missing_columns) > 0) {
    stop("Il test set non contiene colonne richieste dal modello: ", paste(missing_columns, collapse = ", "))
  }

  extra_columns <- setdiff(names(data), names(factor_levels))
  if (length(extra_columns) > 0) {
    data <- data[, setdiff(names(data), extra_columns), drop = FALSE]
  }

  for (column in names(factor_levels)) {
    data[[column]] <- factor(data[[column]], levels = factor_levels[[column]])
  }

  data[, names(factor_levels), drop = FALSE]
}

get_bart_predictions <- function(prediction) {
  if (is.numeric(prediction)) {
    return(prediction)
  }

  if (!is.null(prediction$prob.test.mean)) {
    return(prediction$prob.test.mean)
  }

  if (!is.null(prediction$yhat.test.mean)) {
    return(prediction$yhat.test.mean)
  }

  stop("Predizioni BART non trovate nell'oggetto restituito da predict().")
}

predict_bart_classes <- function(model_path, test_data) {
  if (!requireNamespace("BART", quietly = TRUE)) {
    stop("Pacchetto BART mancante: necessario per calcolare la confusion matrix BART.")
  }

  model_bundle <- readRDS(model_path)
  x_test <- test_data[, setdiff(names(test_data), target_variable), drop = FALSE]
  test_matrix <- build_test_design_matrix(x_test, model_bundle$design_columns)
  predicted_score <- get_bart_predictions(predict(model_bundle$model, test_matrix))
  as.integer(pmin(pmax(predicted_score, 0), 1) >= 0.5)
}

predict_neural_network_classes <- function(model_path, test_data) {
  if (!requireNamespace("torch", quietly = TRUE) || !requireNamespace("luz", quietly = TRUE)) {
    stop("Pacchetti torch/luz mancanti: necessari per calcolare la confusion matrix Neural Network.")
  }

  model_bundle <- readRDS(model_path)
  x_test <- test_data[, setdiff(names(test_data), target_variable), drop = FALSE]
  test_matrix <- build_test_design_matrix(x_test, model_bundle$design_columns)
  x_test_scaled <- apply_scaler(test_matrix, model_bundle$scaler)

  model_luz_path <- model_bundle$model_luz_path
  if (is.null(model_luz_path)) {
    model_luz_path <- paste0(model_path, ".luz")
  }

  if (!file.exists(model_luz_path)) {
    stop("File modello Luz non trovato: ", model_luz_path)
  }

  tensor_dataset <- torch::tensor_dataset(
    torch::torch_tensor(x_test_scaled, dtype = torch::torch_float()),
    torch::torch_tensor(matrix(0, nrow = nrow(x_test_scaled), ncol = 1), dtype = torch::torch_float())
  )

  model <- luz::luz_load(model_luz_path)
  accelerator <- luz::accelerator(cpu = !torch::cuda_is_available())
  logits <- as.numeric(torch::as_array(predict(model, tensor_dataset, accelerator = accelerator)))
  probabilities <- as.numeric(1 / (1 + exp(-logits)))
  as.integer(probabilities >= 0.5)
}

predict_bn_classes <- function(model_path, test_data) {
  if (!requireNamespace("bnlearn", quietly = TRUE)) {
    stop("Pacchetto bnlearn mancante: necessario per calcolare la confusion matrix NB/TAN.")
  }

  model_bundle <- readRDS(model_path)
  prepared_test_data <- prepare_factor_test_data(test_data, model_bundle$factor_levels)
  as.integer(as.character(predict(model_bundle$model, data = prepared_test_data)))
}

get_model_path <- function(model_name, selection) {
  scenario <- scenario_paths[[selection]]

  switch(
    model_name,
    "BART" = scenario$bart_model_path,
    "Neural Network" = scenario$neural_network_model_path,
    "Naive Bayes" = scenario$naive_bayes_model_path,
    "TAN" = scenario$tan_model_path,
    stop("Modello non riconosciuto: ", model_name)
  )
}

predict_model_classes <- function(model_name, model_path, test_data) {
  switch(
    model_name,
    "BART" = predict_bart_classes(model_path, test_data),
    "Neural Network" = predict_neural_network_classes(model_path, test_data),
    "Naive Bayes" = predict_bn_classes(model_path, test_data),
    "TAN" = predict_bn_classes(model_path, test_data),
    stop("Modello non riconosciuto: ", model_name)
  )
}

build_confusion_data <- function(best_scenarios) {
  confusion_data <- data.frame(
    model = character(),
    selection = character(),
    actual = character(),
    predicted = character(),
    n = integer(),
    stringsAsFactors = FALSE
  )

  missing_model_paths <- character()

  for (row_index in seq_len(nrow(best_scenarios))) {
    model_name <- best_scenarios$model[row_index]
    selection <- best_scenarios$selection[row_index]
    model_path <- get_model_path(model_name, selection)

    if (!file.exists(model_path)) {
      missing_model_paths <- c(missing_model_paths, model_path)
      next
    }

    test_path <- scenario_paths[[selection]]$test_path
    test_data <- read.csv(test_path, stringsAsFactors = TRUE)
    actual <- as.integer(as.character(test_data[[target_variable]]))
    predicted <- predict_model_classes(model_name, model_path, test_data)
    table_data <- as.data.frame(table(actual = actual, predicted = predicted), stringsAsFactors = FALSE)
    table_data$model <- model_name
    table_data$selection <- selection
    table_data$n <- as.integer(table_data$Freq)
    table_data$Freq <- NULL

    confusion_data <- rbind(
      confusion_data,
      table_data[, c("model", "selection", "actual", "predicted", "n")]
    )
  }

  if (length(missing_model_paths) > 0) {
    stop(
      "Impossibile calcolare le confusion matrix: model bundle mancanti.\n",
      paste(unique(missing_model_paths), collapse = "\n"),
      "\nRiesegui gli script di training finale prima di generare questa slide."
    )
  }

  confusion_data$actual <- factor(confusion_data$actual, levels = c("1", "0"), labels = c("Diabete si", "Diabete no"))
  confusion_data$predicted <- factor(confusion_data$predicted, levels = c("0", "1"), labels = c("Pred. no", "Pred. si"))
  confusion_data$model <- factor(confusion_data$model, levels = model_levels)
  confusion_data$selection_label <- selection_labels[confusion_data$selection]
  confusion_data$model_label <- paste0(model_labels[as.character(confusion_data$model)], "\n", confusion_data$selection_label)
  confusion_data
}

create_accuracy_heatmap <- function(accuracy_data) {
  ggplot(
    accuracy_data,
    aes(x = selection, y = model, fill = accuracy)
  ) +
    geom_tile(color = background_color, linewidth = 1.8, width = 0.96, height = 0.90) +
    geom_text(aes(label = accuracy_label), family = font_family, fontface = "bold", size = 5.2, color = text_color) +
    scale_x_discrete(labels = selection_labels, position = "top") +
    scale_y_discrete(labels = function(values) model_labels[values]) +
    scale_fill_gradient(low = secondary_color, high = primary_color, guide = "none") +
    labs(title = "Accuracy sul test set", x = NULL, y = NULL) +
    theme_minimal(base_family = font_family) +
    theme(
      plot.background = element_rect(fill = background_color, color = NA),
      panel.background = element_rect(fill = background_color, color = NA),
      panel.grid = element_blank(),
      axis.text.x = element_text(color = text_color, size = 13, face = "bold", margin = margin(b = 8)),
      axis.text.y = element_text(color = text_color, size = 13),
      plot.title = element_text(color = text_color, size = 22, face = "bold", hjust = 0.5, margin = margin(b = 14)),
      plot.margin = margin(8, 40, 10, 40)
    )
}

create_confusion_plot <- function(confusion_data, model_name) {
  model_data <- confusion_data[as.character(confusion_data$model) == model_name, ]
  model_title <- unique(model_data$model_label)

  ggplot(model_data, aes(x = predicted, y = actual, fill = n)) +
    geom_tile(color = background_color, linewidth = 1.4, width = 0.92, height = 0.92) +
    geom_text(aes(label = n), family = font_family, fontface = "bold", size = 4.6, color = text_color) +
    scale_fill_gradient(low = muted_color, high = primary_color, guide = "none") +
    labs(title = model_title, x = NULL, y = NULL) +
    theme_minimal(base_family = font_family) +
    theme(
      plot.background = element_rect(fill = background_color, color = NA),
      panel.background = element_rect(fill = background_color, color = NA),
      panel.grid = element_blank(),
      axis.text.x = element_text(color = text_color, size = 10.5),
      axis.text.y = element_text(color = text_color, size = 10.5),
      plot.title = element_text(color = text_color, size = 14, face = "bold", hjust = 0.5, margin = margin(b = 7)),
      plot.margin = margin(6, 12, 6, 12)
    )
}

accuracy_data <- read_accuracy_data(paths$model_comparison_evaluation_results_path)
best_scenarios <- get_best_scenarios(accuracy_data)
confusion_data <- build_confusion_data(best_scenarios)

write.csv(confusion_data, confusion_output_path, row.names = FALSE)

heatmap_plot <- create_accuracy_heatmap(accuracy_data)
confusion_plots <- lapply(model_levels, function(model_name) {
  create_confusion_plot(confusion_data, model_name)
})

slide_plot <- heatmap_plot /
  wrap_plots(confusion_plots, nrow = 1) +
  plot_layout(heights = c(0.56, 0.44)) +
  plot_annotation(
    title = "Risultati finali dei modelli",
    subtitle = "Confronto accuracy per scenario di selezione e confusion matrix dello scenario migliore per ciascun modello",
    caption = "Le confusion matrix usano i migliori scenari per modello: BART=AIC, Rete neurale=no selection, Naive Bayes=BIC, TAN=AIC.",
    theme = theme(
      plot.background = element_rect(fill = background_color, color = NA),
      plot.title = element_text(
        family = font_family,
        color = text_color,
        size = 34,
        face = "bold",
        hjust = 0.5,
        margin = margin(t = 26, b = 6)
      ),
      plot.subtitle = element_text(
        family = font_family,
        color = text_color,
        size = 14,
        hjust = 0.5,
        margin = margin(b = 4)
      ),
      plot.caption = element_text(
        family = font_family,
        color = text_color,
        size = 9.5,
        hjust = 0.5,
        margin = margin(t = 2, b = 8)
      ),
      plot.margin = margin(0, 34, 0, 34)
    )
  )

ggsave(
  filename = plot_output_path,
  plot = slide_plot,
  device = ragg::agg_png,
  width = slide_width_px,
  height = slide_height_px,
  units = "px",
  dpi = slide_dpi,
  bg = background_color
)

cat("Slide risultati salvata in:", plot_output_path, "\n")
cat("Confusion matrix salvate in:", confusion_output_path, "\n")
