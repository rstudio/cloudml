
#' Read the configuration for a project
#'
#' @param config Name of configuration to read (`NULL` will result in the
#'   active configuration for the current environment being used).
#' @param local_gs Specify a directory name to automatically download local
#'   copies of references to Google Storage data (`gs://`) and then
#'   resolve their values to the path of their local copy.
#'
#' @return List with configuration values
#'
#' @export
project_config <- function(config = NULL, local_gs = "gs") {

  # resolve active configuration
  active <- Sys.getenv("R_CONFIG_ACTIVE", unset = "default")
  config <- config %||% active

  # read the config file
  config <- config::get(config = active, file = "config.yml")

  # merge overlay
  config <- config::merge(config, .globals$overlay)

  # merge parsed command line arguments
  clargs <- tensorflow::parse_arguments()
  config <- config::merge(config, clargs)

  # resolve job dir if it's not available (for 'source'-based workflows)
  if (is.null(config$job_dir)) {
    job_name   <- config$job_name %||% unique_job_name(config = active)
    job_output <- config$job_output %||% unique_job_dir()
    config$job_dir <- file.path(job_output, job_name)
  }

  # resolve gs:// urls (copy them locally if we aren't running on gcloud)
  if (!is.null(local_gs) && !is_gcloud()) {
    resolve_gs_data <- function(value) {
      if (is.list(value) && length(value) > 0)
        lapply(value, resolve_gs_data)
      else if (is_gs_uri(value))
        gs_data(value, local_dir = local_gs)
      else
        value
    }
    config <- lapply(config, resolve_gs_data)
  }

  # return config
  config
}


# set extra config to be used for `cloudml::project_config()`
set_overlay <- function(overlay) {
  .globals$overlay <- overlay
}




