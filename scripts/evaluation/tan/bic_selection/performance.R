source("project/config.R")
source("scripts/evaluation/tan/_common.R")

paths <- project_paths

config <- list(
  selection_label = "bic variable selection",
  model_path = paths$tan_bic_selection_model_path,
  test_path = paths$bic_test_set_path,
  evaluation_results_path = paths$tan_evaluation_results_path
)

invisible(run_tan_test_evaluation(config))
