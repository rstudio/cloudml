# initialize an application such that it can be easily
# deployed on gcloud
initialize_application <- function(application = getwd()) {
  application <- normalizePath(application, winslash = "/", mustWork = TRUE)
  scope_dir(application)

  validate_application(application)

  # copy in 'cloudml' helpers (e.g. the files that act as
  # entrypoints for deployment)
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

validate_application <- function(application) {
  # bail if this doesn't look like a cloudml TensorFlow application
  if (!file.exists(file.path(application,"config.yml"))) {
    fmt <- "'%s' appears not to be a Cloud ML application (missing config.yml)"
    stopf(fmt, application, call. = FALSE)
  }
}

scope_deployment <- function(application = getwd(), config) {
  application <- normalizePath(application, winslash = "/")

  validate_application(application)

  # generate deployment directory
  prefix <- sprintf("cloudml-deploy-%s-", basename(application))
  root <- tempfile(pattern = prefix)
  ensure_directory(root)

  # default excludes plus any additional excludes in the config file
  config <- cloudml::project_config(config = config)
  exclude <- c("local", "jobs", ".git", ".svn")
  exclude <- unique(c(exclude, config$exclude))

  # build deployment bundle
  deployment <- file.path(root, basename(application))
  copy_directory(application,
                 deployment,
                 exclude = exclude,
                 include = config$include)
  defer(unlink(root, recursive = TRUE), envir = parent.frame())
  initialize_application(deployment)

  # move to application path
  owd <- setwd(deployment)
  defer(setwd(owd), envir = parent.frame())

  # return normalized application path
  deployment
}
