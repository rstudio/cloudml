# initialize an application such that it can be easily
# deployed on gcloud
initialize_application <- function(application = getwd()) {
  application <- normalizePath(application, winslash = "/", mustWork = TRUE)
  scope_dir(application)

  # bail if this doesn't look like a cloudml TensorFlow application
  if (!file.exists("config.yml")) {
    fmt <- "'%s' appears not to be a cloudml application (missing config.yml)"
    stopf(fmt, basename(application))
  }

  # copy 'cloudml' deployment helpers to application
  # TODO: use a more targeted approach here + validate that
  # we're not stomping on user files
  if (file.exists("cloudml"))
    unlink("cloudml", recursive = TRUE)

  copy_directory(
    system.file("cloudml/cloudml", package = "cloudml"),
    "cloudml"
  )

  # ensure sub-directories contain an '__init__.py'
  # script, so that they're all included in tarball
  dirs <- list.dirs(application)

  # ignore data directories in the bundle by default
  # TODO: make the pattern here user-configurable?
  dirs <- grep(
    "/(?:jobs|local)",
    dirs,
    invert = TRUE,
    perl = TRUE,
    value = TRUE
  )

  lapply(dirs, function(dir) {
    ensure_file(file.path(dir, "__init__.py"))
  })

  TRUE
}

scope_deployment <- function(application = getwd()) {
  application <- normalizePath(application, winslash = "/")

  # initialize application (tracking what new files were generated)
  # helper function for listing all generated artefacts
  list_files <- function(folder) {
    list.files(folder,
               all.files = TRUE,
               full.names = TRUE,
               recursive = TRUE,
               include.dirs = TRUE)
  }

  old <- list_files(application)
  initialize_application(application)
  new <- list_files(application)

  # clean up the newly generated files and move back
  # to callers directory when the parent function exits
  transient <- setdiff(new, old)
  defer({

    # unlink all transient artefacts
    unlink(transient, recursive = TRUE)

    # clean up any '.pyc' files generated as a side effect
    # of building the package
    pyc <- list.files(
      application,
      pattern    = "\\.pyc$",
      all.files  = TRUE,
      full.names = TRUE,
      recursive  = TRUE
    )
    unlink(pyc)

  }, envir = parent.frame())

  # return normalized application path
  application
}
