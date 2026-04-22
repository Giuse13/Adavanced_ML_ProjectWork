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

project_root <- find_project_root()
project_library_name <- "ambiente_progettodallavalle"
project_library <- file.path(project_root, project_library_name)

if (!dir.exists(project_library)) {
  dir.create(project_library, recursive = TRUE, showWarnings = FALSE)
}

# Use a project-local R library before global libraries.
.libPaths(c(normalizePath(project_library, winslash = "/", mustWork = FALSE), .libPaths()))

options(
  progetto_dallavalle_root = project_root,
  progetto_dallavalle_env = project_library,
  progetto_dallavalle_env_name = project_library_name
)
