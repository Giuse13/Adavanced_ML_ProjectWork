source("project/config.R")
source("scripts/modeling/naive_bayes/_common.R")

paths <- project_paths

config <- list(
  selection_name = "no_selection",
  full_training_path = paths$full_training_set_path,
  model_dir = paths$naive_bayes_no_selection_model_dir,
  model_path = paths$naive_bayes_no_selection_model_path,
  reports_dir = paths$naive_bayes_no_selection_reports_dir,
  structure_plot_path = paths$naive_bayes_no_selection_structure_plot_path
)

cat(
  "Dataset training finale Naive Bayes no selection:",
  normalizePath(config$full_training_path, winslash = "/", mustWork = FALSE),
  "\n"
)

invisible(train_final_naive_bayes_model(config))
