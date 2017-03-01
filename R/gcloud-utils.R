# initialize an application such that it can be easily
# deployed on gcloud
initialize_application <- function(application = getwd()) {
  application <- normalizePath(application, winslash = "/")

  # copy 'cloudml' deployment helpers to application
  cloudml_path <- file.path(application, "cloudml")
  if (file.exists(cloudml_path))
    unlink(cloudml_path, recursive = TRUE)

  copy_directory(
    system.file("cloudml/cloudml", package = "cloudml"),
    cloudml_path
  )

  # ensure sub-directories contain an '__init__.py'
  # script, so that they're all included in tarball
  # (ignore 'data' directories by default)
  dirs <- list.dirs(application)
  dirs <- grep("/(?:jobs|data|gs_data)", dirs, invert = TRUE, perl = TRUE)
  lapply(dirs, function(dir) {
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
