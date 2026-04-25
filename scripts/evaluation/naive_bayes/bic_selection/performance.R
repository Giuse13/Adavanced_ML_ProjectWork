source("project/config.R")
source("scripts/evaluation/naive_bayes/_common.R")

paths <- project_paths

config <- list(
  selection_label = "bic variable selection",
  model_path = paths$naive_bayes_bic_selection_model_path,
  test_path = paths$bic_test_set_path,
  evaluation_results_path = paths$naive_bayes_evaluation_results_path
)

run_naive_bayes_test_evaluation(config)
