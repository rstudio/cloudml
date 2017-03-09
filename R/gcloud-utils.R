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

  copy_directory(
    system.file("cloudml/cloudml", package = "cloudml"),
    "cloudml"
  )

  # ensure sub-directories contain an '__init__.py'
  # script, so that they're all included in tarball
  dirs <- list.dirs(application)
  lapply(dirs, function(dir) {
    ensure_file(file.path(dir, "__init__.py"))
  })

  TRUE
}

scope_deployment <- function(application = getwd()) {
  application <- normalizePath(application, winslash = "/")

  # generate deployment directory
  prefix <- sprintf("cloudml-deploy-%s-", basename(application))
  root <- tempfile(pattern = prefix)
  ensure_directory(root)

  # TODO: read some kind of 'exclude' / 'include' list from the
  # application's config?
  deployment <- file.path(root, basename(application))
  copy_directory(application, deployment, exclude = c("local", "jobs"))
  defer(unlink(root, recursive = TRUE), envir = parent.frame())
  initialize_application(deployment)

  # move to application path
  owd <- setwd(deployment)
  defer(setwd(owd), envir = parent.frame())

  # return normalized application path
  deployment
}
