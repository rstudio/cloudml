cloudml_config <- function(path = getwd()) {

  file <- rprojroot::find_root_file(
    "cloudml.yml",
    criterion = "cloudml.yml",
    path = path
  )

  config <- yaml::yaml.load_file(file)
  config$cloudml

}

#' Initializes Default Configuration File
#'
#' Creates a default 'cloudml.yml' configuration file to initialize the
#' configuration process. This file is created in the current directory,
#' open this file to configure this further.
#'
#' @export
cloudml_init <- function() {
  if (file.exists("cloudml.yml")) {
    warning("cloudml.yml already exists.")
    return()
  }

  config_defaults <- list(
    gcloud = list(
      project = "project-name",
      account = "account@domain.com",
      region  = "us-central1"
    ),
    cloudml = list(
      storage = "gs://project-name/mnist",
      "runtime-version" = "1.2"
    )
  )

  yaml_content <- yaml::as.yaml(config_defaults)
  writeLines(yaml_content, "cloudml.yml")

  invisible(NULL)
}
