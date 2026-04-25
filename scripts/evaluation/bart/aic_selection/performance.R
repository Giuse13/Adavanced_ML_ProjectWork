source("project/config.R")
source("scripts/evaluation/bart/_common.R")

paths <- project_paths

config <- list(
  selection_label = "aic variable selection",
  model_path = paths$bart_aic_selection_model_path,
  test_path = paths$aic_test_set_path
)

run_bart_test_evaluation(config)
