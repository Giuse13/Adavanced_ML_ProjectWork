source("project/config.R")
source("scripts/modeling/naive_bayes/_common.R")

paths <- project_paths

config <- list(
  selection_name = "bic_selection",
  full_training_path = paths$bic_full_training_set_path,
  model_dir = paths$naive_bayes_bic_selection_model_dir,
  model_path = paths$naive_bayes_bic_selection_model_path
)

cat(
  "Dataset training finale Naive Bayes BIC:",
  normalizePath(config$full_training_path, winslash = "/", mustWork = FALSE),
  "\n"
)

train_final_naive_bayes_model(config)
