# initialize an application such that it can be easily
# deployed on gcloud
initialize_application <- function(application = getwd(),
                                   config)
{
  application <- normalizePath(application, winslash = "/", mustWork = TRUE)
  scope_dir(application)

  validate_application(application)

  # copy in 'cloudml' helpers (e.g. the files that act as
  # entrypoints for deployment)
  copy_directory(
    system.file("cloudml/cloudml", package = "cloudml"),
    "cloudml"
  )

  # TODO: where should this be specified?
  # # use packrat for deployment when specified
  # if (isTRUE(config$packrat_enabled)) {
  #
  #   # ignore 'cloudml' for now since it will usually be
  #   # installed from source and we'll want to just reinstall
  #   # from github anyhow -- we can probably change this later
  #   packrat::opts$ignored.packages("cloudml")
  #   packrat::.snapshotImpl(
  #     project = getwd(),
  #     ignore.stale = TRUE,
  #     prompt = FALSE,
  #     snapshot.sources = FALSE,
  #     verbose = FALSE
  #   )
  # }

  # ensure sub-directories contain an '__init__.py'
  # script, so that they're all included in tarball
  dirs <- list.dirs(application)
  lapply(dirs, function(dir) {
    ensure_file(file.path(dir, "__init__.py"))
  })

  TRUE
}

validate_application <- function(application) {
  # TODO: what checks should we perform here?
  TRUE
}

scope_deployment <- function(application = getwd(), config) {
  application <- normalizePath(application, winslash = "/")

  validate_application(application)

  # generate deployment directory
  prefix <- sprintf("cloudml-deploy-%s-", basename(application))
  root <- tempfile(pattern = prefix)
  ensure_directory(root)

  # TODO: where should we draw exclusions from?
  # similarily for inclusions?
  exclude <- c("gs", "jobs", ".git", ".svn")

  # build deployment bundle
  deployment <- file.path(root, basename(application))
  copy_directory(application,
                 deployment,
                 exclude = exclude)
  defer(unlink(root, recursive = TRUE), envir = parent.frame())
  initialize_application(deployment, config)

  envir <- parent.frame()

  # set application directory as active directory
  Sys.setenv(CLOUDML_APPLICATION_DIR = application)
  defer(Sys.unsetenv("CLOUDML_APPLICATION_DIR"), envir = envir)

  # move to application path
  owd <- setwd(deployment)
  defer(setwd(owd), envir = envir)

  # return normalized application path
  deployment
}

write_hypertune <- function(application, overlay) {

  if (is.null(overlay$hypertune))
    return(overlay)

  # attempt to discover user's hyperparameters file
  hypertune <- file.path(application, overlay$hypertune)
  if (!file.exists(hypertune))
    return(overlay)

  hyperparameters <- yaml::yaml.load_file(hypertune)

  # wrap into 'trainingInput:', 'hyperparameters:' keys
  input <- list(
    trainingInput = list(
      hyperparameters = hyperparameters
    )
  )

  # write to target file
  target <- file.path(application, "cloudml/config.yml")
  writeLines(yaml::as.yaml(input), con = target)

  # update in overlay
  overlay$hypertune <- "cloudml/config.yml"

  overlay
}
