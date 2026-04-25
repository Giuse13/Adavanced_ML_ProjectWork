source("project/config.R")
source("scripts/evaluation/naive_bayes/_common.R")

paths <- project_paths

config <- list(
  selection_label = "no variable selection",
  model_path = paths$naive_bayes_no_selection_model_path,
  test_path = paths$test_set_path,
  evaluation_results_path = paths$naive_bayes_evaluation_results_path
)

run_naive_bayes_test_evaluation(config)
