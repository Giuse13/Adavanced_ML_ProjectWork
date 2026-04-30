source("project/config.R")
source("scripts/modeling/neural_network/_common.R")

paths <- project_paths

config <- list(
  selection_name = "bic_selection",
  full_training_path = paths$bic_full_training_set_path,
  best_params_path = paths$neural_network_bic_selection_best_params_path,
  model_dir = paths$neural_network_bic_selection_model_dir,
  model_path = paths$neural_network_bic_selection_model_path
)

cat(
  "Dataset training finale Neural Network BIC:",
  normalizePath(config$full_training_path, winslash = "/", mustWork = FALSE),
  "\n"
)

cat(
  "Best params Neural Network BIC:",
  normalizePath(config$best_params_path, winslash = "/", mustWork = FALSE),
  "\n"
)

invisible(train_final_neural_network_model(config))
