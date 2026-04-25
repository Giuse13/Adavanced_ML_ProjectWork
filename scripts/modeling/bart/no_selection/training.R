source("project/config.R")
source("scripts/modeling/bart/_common.R")

paths <- project_paths

config <- list(
  selection_name = "no_selection",
  full_training_path = paths$full_training_set_path,
  best_params_path = paths$bart_no_selection_best_params_path,
  model_dir = paths$bart_no_selection_model_dir,
  model_path = paths$bart_no_selection_model_path
)

cat(
  "Dataset training finale no selection:",
  normalizePath(config$full_training_path, winslash = "/", mustWork = FALSE),
  "\n"
)
cat(
  "Best params no selection:",
  normalizePath(config$best_params_path, winslash = "/", mustWork = FALSE),
  "\n"
)

train_final_bart_model(config)
