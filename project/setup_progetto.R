find_project_root <- function(start_dir = getwd()) {
  current_dir <- normalizePath(start_dir, winslash = "/", mustWork = FALSE)

  repeat {
    has_git_dir <- dir.exists(file.path(current_dir, ".git"))
    has_readme <- file.exists(file.path(current_dir, "README.md"))
    has_project_profile <- file.exists(file.path(current_dir, ".Rprofile"))

    if (has_git_dir || (has_readme && has_project_profile)) {
      return(current_dir)
    }

    parent_dir <- dirname(current_dir)

    if (identical(parent_dir, current_dir)) {
      return(normalizePath(start_dir, winslash = "/", mustWork = FALSE))
    }

    current_dir <- parent_dir
  }
}

project_root <- getOption(
  "progetto_dallavalle_root",
  default = find_project_root()
)

project_library <- getOption(
  "progetto_dallavalle_env",
  default = file.path(project_root, "ambiente_progettodallavalle")
)

if (!dir.exists(project_library)) {
  dir.create(project_library, recursive = TRUE, showWarnings = FALSE)
}

.libPaths(c(normalizePath(project_library, winslash = "/", mustWork = FALSE), .libPaths()))

message("Ambiente attivo: ", .libPaths()[1])
message("Per installare un pacchetto nel progetto usa, ad esempio:")
message("install.packages('readr', lib = .libPaths()[1])")
message("Per vedere tutte le librerie attive usa:")
message(".libPaths()")
