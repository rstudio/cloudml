# initialize an application such that it can be easily
# deployed on gcloud
initialize_application <- function(application) {
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
