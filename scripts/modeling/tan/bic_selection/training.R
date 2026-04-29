source("project/config.R")
source("scripts/modeling/tan/_common.R")

paths <- project_paths

config <- list(
  selection_name = "bic_selection",
  full_training_path = paths$bic_full_training_set_path,
  model_dir = paths$tan_bic_selection_model_dir,
  model_path = paths$tan_bic_selection_model_path
)

cat(
  "Dataset training finale TAN BIC:",
  normalizePath(config$full_training_path, winslash = "/", mustWork = FALSE),
  "\n"
)

invisible(train_final_tan_model(config))
