source("project/config.R")
source("scripts/modeling/tan/_common.R")

paths <- project_paths

config <- list(
  selection_name = "aic_selection",
  full_training_path = paths$aic_full_training_set_path,
  model_dir = paths$tan_aic_selection_model_dir,
  model_path = paths$tan_aic_selection_model_path
)

cat(
  "Dataset training finale TAN AIC:",
  normalizePath(config$full_training_path, winslash = "/", mustWork = FALSE),
  "\n"
)

invisible(train_final_tan_model(config))
