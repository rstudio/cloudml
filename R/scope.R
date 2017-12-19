#' @importFrom tools file_ext

# initialize an application such that it can be easily
# deployed on gcloud
initialize_application <- function(application = getwd())
{
  application <- normalizePath(application, winslash = "/", mustWork = TRUE)
  scope_dir(application)

  # copy in 'cloudml' helpers (e.g. the files that act as
  # entrypoints for deployment)
  copy_directory(
    system.file("cloudml/cloudml", package = "cloudml"),
    "cloudml"
  )

  # We manage a set of packages during deploy that might require specific versions
  IGNORED <- c(
  )

  packrat::opts$ignored.packages(IGNORED)
  packrat::.snapshotImpl(
    project = getwd(),
    ignore.stale = TRUE,
    prompt = FALSE,
    snapshot.sources = FALSE,
    verbose = FALSE
  )

  # ensure sub-directories contain an '__init__.py'
  # script, so that they're all included in tarball
  dirs <- list.dirs(application)
  lapply(dirs, function(dir) {
    ensure_file(file.path(dir, "__init__.py"))
  })

  TRUE
}

validate_application <- function(application, entrypoint) {
  if (!file.exists(file.path(application, entrypoint)))
    stop("Entrypoint ", entrypoint, " not found under ", application, entrypoint)
}

scope_deployment <- function(id,
                             application = getwd(),
                             context = "local",
                             overlay = NULL,
                             master_type = NULL,
                             entrypoint = NULL,
                             cloudml = NULL,
                             gcloud = NULL)
{
  application <- normalizePath(application, winslash = "/")

  validate_application(application, entrypoint)

  # generate deployment directory
  prefix <- sprintf("cloudml-deploy-%s-", basename(application))
  root <- tempfile(pattern = prefix)
  ensure_directory(root)

  user_exclusions <- strsplit(Sys.getenv("CLOUDML_APPLICATION_EXCLUSIONS", ""), ",")[[1]]

  # similarily for inclusions?
  exclude <- c("gs", "runs", ".git", ".svn", user_exclusions)

  # use generic name to avoid overriding package names, using a dir named
  # keras will override the actual keras package!
  directory <- file.path(root, "cloudml-model")

  # build deployment bundle
  copy_directory(application,
                 directory,
                 exclude = exclude)
  defer(unlink(root, recursive = TRUE), envir = parent.frame())
  initialize_application(directory)

  # copy or create cloudml.yml in bundle dir to maintain state
  if (is.null(cloudml)) cloudml <- cloudml_config()
  cloudml_file <- "cloudml.yml"
  if (is.list(cloudml))
    yaml::write_yaml(cloudml, file.path(directory, cloudml_file))
  else {
    cloudml_ext <- tools::file_ext(cloudml)
    if (!cloudml_ext %in% c("json", "yml"))
      stop(
        "CloudML configuration file expected to have 'json' or 'yml' extension but '",
        cloudml_ext, "' found instead."
      )

    cloudml_file <- paste0("cloudml.", cloudml_ext)
    cloudml_config_path <- file.path(directory, cloudml_file)
    file.copy(cloudml, cloudml_config_path)
  }


  message("Master Type Missing: ", is.null(master_type))


  # copy or create gcloud.yml in bundle dir to maintain state
  gcloud <- gcloud_config(gcloud)
  gcloud_config_path <- file.path(directory, "gcloud.yml")
  if (is.list(gcloud))
    yaml::write_yaml(gcloud, gcloud_config_path)

  envir <- parent.frame()

  # move to application path
  owd <- setwd(directory)
  defer(setwd(owd), envir = envir)

  # serialize deployment information
  info <- list(directory = directory,
               context = context,
               entrypoint = entrypoint,
               overlay = overlay,
               id = id,
               cloudml_file = cloudml_file)
  ensure_directory("cloudml")
  saveRDS(info, file = "cloudml/deploy.rds")

  info
}
