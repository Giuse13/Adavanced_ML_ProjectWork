source("project/config.R")
source("scripts/evaluation/neural_network/_common.R")

paths <- project_paths

config <- list(
  selection_label = "bic variable selection",
  model_path = paths$neural_network_bic_selection_model_path,
  test_path = paths$bic_test_set_path,
  evaluation_results_path = paths$neural_network_evaluation_results_path
)

run_neural_network_test_evaluation(config)
