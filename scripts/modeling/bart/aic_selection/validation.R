source("project/config.R")
source("scripts/modeling/bart/_common.R")

paths <- project_paths

config <- list(
  selection_name = "aic_selection",
  training_path = paths$aic_training_set_path,
  validation_path = paths$aic_validation_set_path,
  reports_dir = paths$bart_aic_selection_reports_dir,
  validation_results_path = paths$bart_aic_selection_validation_results_path,
  best_params_path = paths$bart_aic_selection_best_params_path
)

run_bart_validation(config)
