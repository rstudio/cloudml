#' @importFrom tools file_ext

# initialize an application such that it can be easily
# deployed on gcloud
initialize_application <- function(application = getwd(), dry_run = FALSE)
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
  IGNORED <- getOption("cloudml.ignored.packages", c())

  packrat::opts$ignored.packages(IGNORED)
  packrat::.snapshotImpl(
    project = getwd(),
    ignore.stale = getOption("cloudml.snapshot.ignore.stale", FALSE),
    prompt = FALSE,
    snapshot.sources = getOption("cloudml.snapshot.sources", FALSE),
    verbose = getOption("cloudml.snapshot.verbose", dry_run),
    fallback.ok = getOption("cloudml.snapshot.fallback.ok", FALSE)
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
    stop("Entrypoint ", entrypoint, " not found under ", application)
}

scope_deployment <- function(id,
                             application = getwd(),
                             context = "local",
                             overlay = NULL,
                             entrypoint = NULL,
                             cloudml = NULL,
                             gcloud = NULL,
                             dry_run = FALSE)
{
  if (!is.list(cloudml)) stop("'cloudml' expected to be a configuration list")
  if (!is.list(gcloud)) stop("'gcloud' expected to be a configuration list")

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

  if (dry_run)
    message("\nTemporary deployment path ", root, " will not be automatically removed in dry runs.")
  else
    defer(unlink(root, recursive = TRUE), envir = parent.frame())

  initialize_application(directory, dry_run = dry_run)

  # copy or create cloudml.yml in bundle dir to maintain state
  cloudml_file <- "cloudml.yml"
  yaml::write_yaml(cloudml, file.path(directory, cloudml_file))

  # copy or create gcloud.yml in bundle dir to maintain state
  gcloud_config_path <- file.path(directory, "gcloud.yml")
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
  saveRDS(info, file = "cloudml/deploy.rds", version = 2)

  info
}
