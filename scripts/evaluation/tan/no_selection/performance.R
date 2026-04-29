source("project/config.R")
source("scripts/evaluation/tan/_common.R")

paths <- project_paths

config <- list(
  selection_label = "no variable selection",
  model_path = paths$tan_no_selection_model_path,
  test_path = paths$test_set_path,
  evaluation_results_path = paths$tan_evaluation_results_path
)

invisible(run_tan_test_evaluation(config))
