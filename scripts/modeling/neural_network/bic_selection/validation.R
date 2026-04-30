source("project/config.R")
source("scripts/modeling/neural_network/_common.R")

paths <- project_paths

config <- list(
  selection_name = "bic_selection",
  training_path = paths$bic_training_set_path,
  validation_path = paths$bic_validation_set_path,
  reports_dir = paths$neural_network_bic_selection_reports_dir,
  validation_results_path = paths$neural_network_bic_selection_validation_results_path,
  best_params_path = paths$neural_network_bic_selection_best_params_path
)

run_neural_network_validation(config)
