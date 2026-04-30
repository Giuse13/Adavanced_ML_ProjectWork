source("project/config.R")
source("scripts/modeling/neural_network/_common.R")

paths <- project_paths

config <- list(
  selection_name = "no_selection",
  full_training_path = paths$full_training_set_path,
  best_params_path = paths$neural_network_no_selection_best_params_path,
  model_dir = paths$neural_network_no_selection_model_dir,
  model_path = paths$neural_network_no_selection_model_path
)

cat(
  "Dataset training finale Neural Network No Selection:",
  normalizePath(config$full_training_path, winslash = "/", mustWork = FALSE),
  "\n"
)

cat(
  "Best params Neural Network No Selection:",
  normalizePath(config$best_params_path, winslash = "/", mustWork = FALSE),
  "\n"
)

invisible(train_final_neural_network_model(config))
