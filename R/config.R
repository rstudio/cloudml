cloudml_config <- function(path = getwd()) {

  file <- find_cloudml_config(path)
  if (is.null(file))
    return(list())

  config <- yaml::yaml.load_file(file)
  config$cloudml

}

find_cloudml_config <- function(path = getwd()) {
  tryCatch(
    rprojroot::find_root_file(
      "cloudml.yml",
      criterion = "cloudml.yml",
      path = path
    ),
    error = function(e) NULL
  )
}


#' Initializes Default Configuration File
#'
#' Creates a default 'cloudml.yml' configuration file to initialize the
#' configuration process. This file is created in the current directory,
#' open this file to configure this further.
#'
#' @export
cloudml_init <- function(name, project = name, storage = paste0("gs://", project)) {

  # check if the directory already exists
  if (file_test("-d", name))
    stop("Directory named '", name, "' already exists'")

  # create directory
  dir.create(name)
  message(paste0("- Created project directory '", name, "'"))

  # copy template training script
  file.copy(system.file("templates", "train.R", package = "cloudml"),
            to = name)
  message("- Created training script 'train.R'")

  # create config.yml file
  cloudml_yml <- file.path(name, "cloudml.yml")
  config_defaults <- list(
    gcloud = list(
      project = project
    ),
    cloudml = list(
      storage = storage
    )
  )
  yaml_content <- yaml::as.yaml(config_defaults)
  writeLines(yaml_content, cloudml_yml)
  message("- Created config file 'cloudml.yml':")
  message(paste(paste("  ", readLines(cloudml_yml)), collapse = "\n"))


  # return path invisibly
  invisible(name)
}
