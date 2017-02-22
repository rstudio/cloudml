stopf <- function(fmt, ..., call. = TRUE, domain = NULL) {
  stop(simpleError(
    sprintf(fmt, ...),
    if (call.) sys.call(sys.parent())
  ))
}

ensure_directory <- function(path) {

  if (file.exists(path)) {
    info <- file.info(path)
    if (identical(info$isdir, TRUE))
      return(invisible(path))
    stopf("path '%s' exists but is not a directory", path)
  }

  if (!dir.create(path, recursive = TRUE))
    stopf("failed to create directory at path '%s'", path)

  invisible(path)

}

ensure_file <- function(path) {

  if (file.exists(path)) {
    info <- file.info(path)
    if (identical(info$isdir, FALSE))
      return(invisible(path))
    stopf("path '%s' exists but is not a file", path)
  }

  if (!file.create(path))
    stopf("failed to create file at path '%s'", path)

  invisible(path)
}


user_setting <- function(option, default = NULL) {

  # check environment variable of associated name
  env_name <- gsub(".", "_", toupper(option), fixed = TRUE)
  env_val <- Sys.getenv(env_name, unset = NA)
  if (!is.na(env_val))
    return(env_val)

  # check R option
  opt_val <- getOption(option)
  if (!is.null(opt_val))
    return(opt_val)

  # no setting available; return default
  default

}

random_string <- function(prefix = "") {
  basename(tempfile(prefix))
}
