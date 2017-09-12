`%||%` <- function(x, y) if (is.null(x)) y else x

printf <- function(fmt, ...) {
  cat(sprintf(fmt, ...), sep = "\n")
}

stopf <- function(fmt, ..., call. = TRUE, domain = NULL) {
  stop(simpleError(
    sprintf(fmt, ...),
    if (call.) sys.call(sys.parent())
  ))
}

warnf <- function(fmt, ..., call. = TRUE)
{
  warning(simpleWarning(
    sprintf(fmt, ...),
    if (call.) sys.call(sys.parent())
  ))
}

copy_directory <- function(source,
                           target,
                           overwrite = TRUE,
                           exclude = character(),
                           include = character()) {

  # source dir
  source <- normalizePath(source, winslash = "/", mustWork = TRUE)

  # target dir
  if (file.exists(target)) {
    if (!overwrite)
      stopf("a file already exists at path '%s'", target)
    unlink(target, recursive = TRUE)
  }
  dir.create(target)

  # get the original top level file listing
  all_files <- list.files(source, all.files = TRUE, no.. = TRUE)

  # apply excludes to the top level listing
  exclude <- utils::glob2rx(exclude)
  files <- all_files
  for (pattern in exclude)
    files <- files[!grepl(pattern, files)]

  # apply back includes
  include <- utils::glob2rx(include)
  for (pattern in include) {
    include_files <- all_files[grepl(pattern, all_files)]
    files <- unique(c(files, include_files))
  }

  # copy the files
  file.copy(from = file.path(source, files),
            to = target,
            recursive = TRUE)
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

timestamp_string <- function() {
  time <- format(Sys.time(), "%Y_%m_%d_%H%M%OS3", tz = "GMT")
  gsub(".", "", time, fixed = TRUE)
}

unique_job_name <- function(application = getwd(), config = "default") {
  application <- normalizePath(application, mustWork = TRUE)
  sprintf(
    "%s_%s_%s",
    basename(application),
    config,
    timestamp_string()
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

# wrapper for system2 that ensure we are using the same version of Python
# that the tensorflow package will bind to
gexec <- function(command, args = character(), stdout = "", stderr = "", ...) {

  # execute command
  result <- system2(command, args, stdout, stderr, ...)

  # check for errors given different return value conventions
  if (isTRUE(stdout) || isTRUE(stderr)) {
    status <- attr(result, "status")
    if (!is.null(status)) {
      errmsg <- attr(result, "errmsg")
      if (is.null(errmsg))
        errmsg <- paste0("Error ", status, " occurred running command ", command)
      stop(errmsg)
    }
  } else if (result != 0) {
    stop("Error ", result, " occurred running command ", command)
  }

  # return result
  result
}

enumerate <- function(X, FUN, ...) {
  N <- names(X)
  lapply(seq_along(N), function(i) {
    FUN(N[[i]], X[[i]], ...)
  })
}

flatten_list <- function(list) {
  mutated <- list
  while (TRUE) {
    types <- lapply(mutated, typeof)
    if (!"list" %in% types) break
    mutated <- unlist(mutated, recursive = FALSE)
  }
  mutated
}

# Generates 'setup.py' in the parent directory of an application,
# and removes it when the calling function finishes execution.
scope_setup_py <- function(application,
                           envir = parent.frame())
{
  scope_dir(dirname(application))

  if (file.exists("setup.py"))
    return()

  file.copy(
    system.file("cloudml/setup.py", package = "cloudml"),
    "setup.py",
    overwrite = TRUE
  )

  setup.py <- normalizePath("setup.py")
  defer(unlink(setup.py), envir = parent.frame())
}

as_aliased_path <- function(path) {
  home <- gsub("/$", "", path.expand("~/"))
  pattern <- paste0("^", home)
  sub(pattern, "~", path)
}
