source("project/config.R")
source("scripts/modeling/bart/_common.R")

paths <- project_paths

config <- list(
  selection_name = "aic_selection",
  full_training_path = paths$aic_full_training_set_path,
  best_params_path = paths$bart_aic_selection_best_params_path,
  model_dir = paths$bart_aic_selection_model_dir,
  model_path = paths$bart_aic_selection_model_path
)

train_final_bart_model(config)
