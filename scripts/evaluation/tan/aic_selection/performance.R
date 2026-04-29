source("project/config.R")
source("scripts/evaluation/tan/_common.R")

paths <- project_paths

config <- list(
  selection_label = "aic variable selection",
  model_path = paths$tan_aic_selection_model_path,
  test_path = paths$aic_test_set_path,
  evaluation_results_path = paths$tan_evaluation_results_path
)

invisible(run_tan_test_evaluation(config))
