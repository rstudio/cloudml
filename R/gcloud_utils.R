# initialize an application such that it can be easily
# deployed on gcloud
initialize_application <- function(application = getwd()) {
  application <- normalizePath(application, winslash = "/")

  # copy 'deploy.py' script to top-level directory
  file.copy(
    system.file("cloudml/deploy.py", package = "cloudml"),
    file.path(application, "deploy.py"),
    overwrite = TRUE
  )

  # ensure all sub-directories contain an '__init__.py'
  # script, so that they're all included in tarball
  dirs <- list.dirs(application)
  lapply(dirs, function(dir) {
    init.py <- file.path(dir, "__init__.py")
    ensure_file(file.path(dir, "__init__.py"))
  })

  TRUE
}

scope_deployment <- function(application = getwd()) {
  application <- normalizePath(application, winslash = "/")

  # initialize application (tracking what new files were generated)
  old <- list.files(application, all.files = TRUE, full.names = TRUE, recursive = TRUE)
  initialize_application(application)
  new <- list.files(application, all.files = TRUE, full.names = TRUE, recursive = TRUE)

  # clean up the newly generated files and move back
  # to callers directory when the parent function exits
  transient <- setdiff(new, old)
  defer({
    unlink(transient, recursive = TRUE)

    # also clean up any '__init__.pyc' files
    pyc <- list.files(
      "__init__.pyc$",
      application,
      all.files = TRUE,
      full.names = TRUE,
      recursive = TRUE
    )

    unlink(pyc)
  }, envir = parent.frame())

  # return normalized application path
  application
}
