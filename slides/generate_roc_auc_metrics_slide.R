source("project/config.R")

paths <- project_paths

required_packages <- c("BART", "bnlearn", "ggplot2", "luz", "patchwork", "pROC", "ragg", "systemfonts", "torch")
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

plot_output_path <- file.path(slides_figures_dir, "model_roc_auc_metrics.png")
prediction_output_path <- file.path(slides_data_dir, "best_models_predictions.csv")
roc_output_path <- file.path(slides_data_dir, "best_models_roc_points.csv")
metrics_output_path <- file.path(slides_data_dir, "best_models_classification_metrics.csv")

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

selection_labels <- c(
  "no variable selection" = "No selection",
  "aic variable selection" = "AIC MB",
  "bic variable selection" = "BIC MB"
)

model_labels <- c(
  "BART" = "BART",
  "Neural Network" = "Rete neurale",
  "Naive Bayes" = "Naive Bayes",
  "TAN" = "TAN"
)

model_colors <- c(
  "BART" = "#d64b3c",
  "Neural Network" = "#226fbb",
  "Naive Bayes" = "#f2a51a",
  "TAN" = "#5b3f99"
)

legend_model_labels <- c(
  "BART" = "BART",
  "Neural Network" = "NN",
  "Naive Bayes" = "NB",
  "TAN" = "TAN"
)

legend_selection_labels <- c(
  "No selection" = "no sel.",
  "AIC MB" = "AIC",
  "BIC MB" = "BIC"
)

best_models <- data.frame(
  model = c("BART", "Neural Network", "Naive Bayes", "TAN"),
  selection = c("aic variable selection", "no variable selection", "bic variable selection", "aic variable selection"),
  model_path = c(
    paths$bart_aic_selection_model_path,
    paths$neural_network_no_selection_model_path,
    paths$naive_bayes_bic_selection_model_path,
    paths$tan_aic_selection_model_path
  ),
  test_path = c(
    paths$aic_test_set_path,
    paths$test_set_path,
    paths$bic_test_set_path,
    paths$aic_test_set_path
  ),
  stringsAsFactors = FALSE
)

for (required_path in c(best_models$model_path, best_models$test_path)) {
  if (!file.exists(required_path)) {
    stop("File richiesto non trovato: ", required_path)
  }
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

predict_bart_probability <- function(model_path, test_data) {
  model_bundle <- readRDS(model_path)
  x_test <- test_data[, setdiff(names(test_data), target_variable), drop = FALSE]
  test_matrix <- build_test_design_matrix(x_test, model_bundle$design_columns)
  predicted_score <- get_bart_predictions(predict(model_bundle$model, test_matrix))
  pmin(pmax(as.numeric(predicted_score), 0), 1)
}

predict_neural_network_probability <- function(model_path, test_data) {
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
  as.numeric(1 / (1 + exp(-logits)))
}

predict_bn_probability <- function(model_path, test_data) {
  model_bundle <- readRDS(model_path)
  prepared_test_data <- prepare_factor_test_data(test_data, model_bundle$factor_levels)
  predicted <- predict(
    object = model_bundle$model,
    data = prepared_test_data,
    prob = TRUE
  )
  probability_matrix <- attr(predicted, "prob")

  if (is.null(probability_matrix) || !("1" %in% rownames(probability_matrix))) {
    stop("Probabilita' della classe 1 non trovata per: ", model_path)
  }

  as.numeric(probability_matrix["1", ])
}

predict_model_probability <- function(model_name, model_path, test_data) {
  switch(
    model_name,
    "BART" = predict_bart_probability(model_path, test_data),
    "Neural Network" = predict_neural_network_probability(model_path, test_data),
    "Naive Bayes" = predict_bn_probability(model_path, test_data),
    "TAN" = predict_bn_probability(model_path, test_data),
    stop("Modello non riconosciuto: ", model_name)
  )
}

safe_divide <- function(numerator, denominator) {
  ifelse(denominator == 0, NA_real_, numerator / denominator)
}

compute_metrics <- function(actual, probability, threshold = 0.5) {
  predicted <- as.integer(probability >= threshold)
  tp <- sum(actual == 1 & predicted == 1)
  tn <- sum(actual == 0 & predicted == 0)
  fp <- sum(actual == 0 & predicted == 1)
  fn <- sum(actual == 1 & predicted == 0)

  sensitivity <- safe_divide(tp, tp + fn)
  specificity <- safe_divide(tn, tn + fp)
  precision <- safe_divide(tp, tp + fp)
  npv <- safe_divide(tn, tn + fn)
  fpr <- safe_divide(fp, fp + tn)
  fnr <- safe_divide(fn, fn + tp)
  f1 <- safe_divide(2 * precision * sensitivity, precision + sensitivity)

  data.frame(
    TP = tp,
    FP = fp,
    TN = tn,
    FN = fn,
    TP_pct = safe_divide(tp, tp + tn + fp + fn),
    FP_pct = safe_divide(fp, tp + tn + fp + fn),
    TN_pct = safe_divide(tn, tp + tn + fp + fn),
    FN_pct = safe_divide(fn, tp + tn + fp + fn),
    accuracy = safe_divide(tp + tn, tp + tn + fp + fn),
    sensitivity_power = sensitivity,
    specificity = specificity,
    precision_ppv = precision,
    npv = npv,
    fpr = fpr,
    fnr = fnr,
    f1 = f1,
    balanced_accuracy = mean(c(sensitivity, specificity), na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

build_predictions <- function(best_models_data) {
  predictions <- data.frame()

  for (row_index in seq_len(nrow(best_models_data))) {
    model_name <- best_models_data$model[row_index]
    selection <- best_models_data$selection[row_index]
    model_path <- best_models_data$model_path[row_index]
    test_path <- best_models_data$test_path[row_index]
    test_data <- read.csv(test_path, stringsAsFactors = TRUE)
    actual <- as.integer(as.character(test_data[[target_variable]]))
    probability <- predict_model_probability(model_name, model_path, test_data)

    predictions <- rbind(
      predictions,
      data.frame(
        model = model_name,
        model_label = unname(model_labels[model_name]),
        selection = selection,
        selection_label = unname(selection_labels[selection]),
        actual = actual,
        probability = probability,
        predicted = as.integer(probability >= 0.5),
        stringsAsFactors = FALSE
      )
    )
  }

  predictions
}

build_roc_data <- function(predictions) {
  roc_data <- data.frame()
  auc_data <- data.frame()

  for (model_name in unique(predictions$model)) {
    model_predictions <- predictions[predictions$model == model_name, ]
    roc_object <- pROC::roc(
      response = model_predictions$actual,
      predictor = model_predictions$probability,
      levels = c(0, 1),
      direction = "<",
      quiet = TRUE
    )

    coords <- pROC::coords(
      roc_object,
      x = "all",
      ret = c("specificity", "sensitivity"),
      transpose = FALSE
    )

    model_roc_data <- data.frame(
      model = model_name,
      model_label = unname(model_labels[model_name]),
      fpr = 1 - coords$specificity,
      sensitivity = coords$sensitivity,
      stringsAsFactors = FALSE
    )

    roc_data <- rbind(roc_data, model_roc_data)
    auc_data <- rbind(
      auc_data,
      data.frame(
        model = model_name,
        auc = as.numeric(pROC::auc(roc_object)),
        stringsAsFactors = FALSE
      )
    )
  }

  list(roc = roc_data, auc = auc_data)
}

build_metrics_data <- function(predictions, auc_data) {
  metrics_data <- data.frame()

  for (model_name in unique(predictions$model)) {
    model_predictions <- predictions[predictions$model == model_name, ]
    metrics <- compute_metrics(model_predictions$actual, model_predictions$probability)
    metrics$model <- model_name
    metrics$model_label <- unname(model_labels[model_name])
    metrics$selection_label <- unique(model_predictions$selection_label)
    metrics$auc <- auc_data$auc[auc_data$model == model_name]
    metrics_data <- rbind(metrics_data, metrics)
  }

  metrics_data
}

create_roc_plot <- function(roc_data, metrics_data) {
  auc_labels <- metrics_data[, c("model", "model_label", "selection_label", "auc")]
  auc_labels$label <- paste0(
    unname(legend_model_labels[auc_labels$model]),
    " ",
    unname(legend_selection_labels[auc_labels$selection_label]),
    " = ",
    sprintf("%.3f", auc_labels$auc)
  )

  ggplot(roc_data, aes(x = fpr, y = sensitivity, color = model)) +
    geom_abline(slope = 1, intercept = 0, color = grid_color, linewidth = 0.55, linetype = "dashed") +
    geom_path(linewidth = 0.3, lineend = "round") +
    scale_color_manual(
      values = model_colors,
      breaks = auc_labels$model,
      labels = auc_labels$label
    ) +
    coord_equal(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE) +
    labs(
      title = "ROC curve dei migliori modelli",
      x = "False positive rate",
      y = "True positive rate / sensitivita'",
      color = NULL
    ) +
    theme_minimal(base_family = font_family) +
    theme(
      plot.background = element_rect(fill = background_color, color = NA),
      panel.background = element_rect(fill = background_color, color = NA),
      panel.grid = element_line(color = grid_color, linewidth = 0.30),
      axis.text = element_text(color = text_color, size = 10.5),
      axis.title = element_text(color = text_color, size = 12),
      plot.title = element_text(color = text_color, size = 22, face = "bold", hjust = 0.5, margin = margin(b = 10)),
      legend.position = c(0.63, 0.13),
      legend.direction = "vertical",
      legend.justification = c(0, 0),
      legend.text = element_text(color = text_color, size = 8.3),
      legend.background = element_rect(fill = background_color, color = NA),
      legend.key = element_rect(fill = background_color, color = NA),
      legend.key.width = grid::unit(16, "pt"),
      legend.key.height = grid::unit(9, "pt"),
      plot.margin = margin(8, 18, 8, 26)
    )
}

create_rate_heatmap <- function(metrics_data) {
  rate_columns <- c("auc", "sensitivity_power", "specificity", "precision_ppv", "f1")
  rate_labels <- c(
    auc = "AUC",
    sensitivity_power = "Sensitivita'\nTPR",
    specificity = "Specificita'",
    precision_ppv = "Precisione",
    f1 = "F1"
  )

  long_data <- data.frame()

  for (column in rate_columns) {
    long_data <- rbind(
      long_data,
      data.frame(
        model = metrics_data$model,
        model_label = metrics_data$model_label,
        metric = column,
        metric_label = unname(rate_labels[column]),
        value = metrics_data[[column]],
        label = sprintf("%.3f", metrics_data[[column]]),
        stringsAsFactors = FALSE
      )
    )
  }

  long_data$model_label <- factor(long_data$model_label, levels = rev(unname(model_labels[unique(metrics_data$model)])))
  long_data$metric_label <- factor(long_data$metric_label, levels = unname(rate_labels[rate_columns]))

  long_data$scaled_value <- NA_real_
  for (column in rate_columns) {
    column_rows <- long_data$metric == column
    column_values <- long_data$value[column_rows]
    column_range <- range(column_values, na.rm = TRUE)

    if (diff(column_range) == 0) {
      long_data$scaled_value[column_rows] <- 0.5
    } else {
      long_data$scaled_value[column_rows] <- (column_values - column_range[1]) / diff(column_range)
    }
  }

  ggplot(long_data, aes(x = metric_label, y = model_label, fill = scaled_value)) +
    geom_tile(color = background_color, linewidth = 1.2, width = 0.94, height = 0.86) +
    geom_text(aes(label = label), family = font_family, fontface = "bold", size = 4.0, color = text_color) +
    scale_fill_gradient(low = "#f2e8df", high = primary_color, limits = c(0, 1), guide = "none") +
    labs(
      title = expression(bold("Metriche") ~ scriptstyle("(soglia 0.5)")),
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_family = font_family) +
    theme(
      plot.background = element_rect(fill = background_color, color = NA),
      panel.background = element_rect(fill = background_color, color = NA),
      panel.grid = element_blank(),
      axis.text.x = element_text(color = text_color, size = 9.5, face = "bold"),
      axis.text.y = element_text(color = text_color, size = 10.5),
      plot.title = element_text(color = text_color, size = 18, face = "bold", hjust = 0.5, margin = margin(b = 8)),
      plot.margin = margin(8, 12, 8, 12)
    )
}

create_count_table <- function(metrics_data) {
  count_columns <- c("TP", "FP", "TN", "FN")
  percent_columns <- paste0(count_columns, "_pct")

  long_data <- data.frame()

  for (column_index in seq_along(count_columns)) {
    column <- count_columns[column_index]
    percent_column <- percent_columns[column_index]

    long_data <- rbind(
      long_data,
      data.frame(
        model = metrics_data$model,
        model_label = metrics_data$model_label,
        metric = column,
        value = metrics_data[[percent_column]],
        label = sprintf("%.1f%%", 100 * metrics_data[[percent_column]]),
        stringsAsFactors = FALSE
      )
    )
  }

  long_data$model_label <- factor(long_data$model_label, levels = rev(unname(model_labels[unique(metrics_data$model)])))
  long_data$metric <- factor(long_data$metric, levels = count_columns)

  ggplot(long_data, aes(x = metric, y = model_label, fill = value)) +
    geom_tile(color = background_color, linewidth = 1.2, width = 0.94, height = 0.86) +
    geom_text(aes(label = label), family = font_family, fontface = "bold", size = 4.0, color = text_color) +
    scale_fill_gradient(low = muted_color, high = secondary_color, guide = "none") +
    labs(title = "Confusion matrix in percentuale", x = NULL, y = NULL) +
    theme_minimal(base_family = font_family) +
    theme(
      plot.background = element_rect(fill = background_color, color = NA),
      panel.background = element_rect(fill = background_color, color = NA),
      panel.grid = element_blank(),
      axis.text.x = element_text(color = text_color, size = 10, face = "bold"),
      axis.text.y = element_text(color = text_color, size = 10.5),
      plot.title = element_text(color = text_color, size = 18, face = "bold", hjust = 0.5, margin = margin(b = 8)),
      plot.margin = margin(8, 12, 8, 12)
    )
}

predictions <- build_predictions(best_models)
roc_results <- build_roc_data(predictions)
metrics_data <- build_metrics_data(predictions, roc_results$auc)

write.csv(predictions, prediction_output_path, row.names = FALSE)
write.csv(roc_results$roc, roc_output_path, row.names = FALSE)
write.csv(metrics_data, metrics_output_path, row.names = FALSE)

roc_plot <- create_roc_plot(roc_results$roc, metrics_data)
rate_heatmap <- create_rate_heatmap(metrics_data)
count_table <- create_count_table(metrics_data)

slide_plot <- roc_plot |
  (rate_heatmap / count_table) +
  plot_layout(widths = c(0.58, 0.42)) +
  plot_annotation(
    title = "ROC/AUC e diagnostica dei migliori modelli",
    subtitle = "Confronto delle probabilita' predette e delle metriche derivate dalla confusion matrix",
    caption = "Sensitivita' = TP / (TP + FN). Le metriche sono calcolate sui test set dei migliori scenari per modello.",
    theme = theme(
      plot.background = element_rect(fill = background_color, color = NA),
      plot.title = element_text(
        family = font_family,
        color = text_color,
        size = 32,
        face = "bold",
        hjust = 0.5,
        margin = margin(t = 24, b = 6)
      ),
      plot.subtitle = element_text(
        family = font_family,
        color = text_color,
        size = 14,
        hjust = 0.5,
        margin = margin(b = 8)
      ),
      plot.caption = element_text(
        family = font_family,
        color = text_color,
        size = 9.5,
        hjust = 0.5,
        margin = margin(t = 4, b = 8)
      ),
      plot.margin = margin(0, 30, 0, 30)
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

cat("Slide ROC/AUC salvata in:", plot_output_path, "\n")
cat("Predizioni salvate in:", prediction_output_path, "\n")
cat("Punti ROC salvati in:", roc_output_path, "\n")
cat("Metriche salvate in:", metrics_output_path, "\n")
