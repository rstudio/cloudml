`%||%` <- function(x, y) if (is.null(x)) y else x

stopf <- function(fmt, ..., call. = TRUE, domain = NULL) {
  stop(simpleError(
    sprintf(fmt, ...),
    if (call.) sys.call(sys.parent())
  ))
}

# TODO: Windows
copy_directory <- function(source, target, overwrite = TRUE) {

  if (!file.exists(source))
    stopf("no directory at path '%s'", source)

  if (file.exists(target)) {
    if (!overwrite)
      stopf("a file already exists at path '%s'", target)
    unlink(target, recursive = TRUE)
  }

  system(paste(
    "cp -R",
    shQuote(source),
    shQuote(target)
  ))

  isTRUE(file.info(target)$isdir)
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

random_job_name <- function(application = getwd(), config = "default") {
  application <- normalizePath(application, mustWork = TRUE)
  sprintf(
    "%s_%s_%s_%i",
    basename(application),
    config,
    format(Sys.time(), "%Y%m%d"),
    as.integer(Sys.time())
  )
}

defer <- function(expr, envir = parent.frame()) {

  # Create a call that must be evaluated in the parent frame (as
  # that's where functions and symbols need to be resolved)
  call <- substitute(
    evalq(expr, envir = envir),
    list(expr = substitute(expr), envir = parent.frame())
  )

  # Use 'do.call' with 'on.exit' to attach the evaluation to
  # the exit handlrs of the selected frame
  do.call(base::on.exit, list(substitute(call), add = TRUE), envir = envir)
}

scope_dir <- function(dir) {
  owd <- setwd(dir)
  defer(setwd(owd), parent.frame())
}
