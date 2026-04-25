source("project/config.R")
source("scripts/evaluation/bart/_common.R")

paths <- project_paths

config <- list(
  selection_label = "bic variable selection",
  model_path = paths$bart_bic_selection_model_path,
  test_path = paths$bic_test_set_path
)

run_bart_test_evaluation(config)
