source("project/config.R")
source("scripts/modeling/tan/_common.R")

paths <- project_paths

config <- list(
  selection_name = "no_selection",
  full_training_path = paths$full_training_set_path,
  model_dir = paths$tan_no_selection_model_dir,
  model_path = paths$tan_no_selection_model_path,
  reports_dir = paths$tan_no_selection_reports_dir,
  structure_plot_path = paths$tan_no_selection_structure_plot_path
)

cat(
  "Dataset training finale TAN no selection:",
  normalizePath(config$full_training_path, winslash = "/", mustWork = FALSE),
  "\n"
)

invisible(train_final_tan_model(config))
