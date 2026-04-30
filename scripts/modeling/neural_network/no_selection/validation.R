source("project/config.R")
source("scripts/modeling/neural_network/_common.R")

paths <- project_paths

config <- list(
  selection_name = "no_selection",
  training_path = paths$training_set_path,
  validation_path = paths$validation_set_path,
  reports_dir = paths$neural_network_no_selection_reports_dir,
  validation_results_path = paths$neural_network_no_selection_validation_results_path,
  best_params_path = paths$neural_network_no_selection_best_params_path
)

run_neural_network_validation(config)
