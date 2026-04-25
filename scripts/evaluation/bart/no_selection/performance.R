source("project/config.R")
source("scripts/evaluation/bart/_common.R")

paths <- project_paths

config <- list(
  selection_label = "no variable selection",
  model_path = paths$bart_no_selection_model_path,
  test_path = paths$test_set_path
)

run_bart_test_evaluation(config)
