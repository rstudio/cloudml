# Copies an application to a directory of the same name in
# the R session's temporary directory, and then deploys that.
generate_deployment_dir <- function(application) {

  # Generate deployment directory
  deploy_dir <- tempfile("cloudml-deployment-")
  ensure_directory(deploy_dir)

  app_dir <- file.path(deploy_dir, basename(application))
  system(paste("cp -R", shQuote(application), shQuote(app_dir)))

  owd <- setwd(app_dir)
  on.exit(setwd(owd), add = TRUE)

  # Overlay files needed to deploy directory as though
  # it were a Python package
  resource_dir <- system.file("cloudml", package = "cloudml")
  resource_paths <- list.files(resource_path, recursive = TRUE)

  sources <- file.path(resource_dir, resource_paths)
  targets <- file.path(deploy_dir, sub("cloudml", basename(application), resource_paths))
  file.copy(sources, targets, overwrite = TRUE)

  # Return newly generated deployment directory
  deploy_dir
}
