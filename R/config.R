
#' Read the configuration for a CloudML application
#'
#' @param local_gs Specify a directory name to automatically download local
#'   copies of references to Google Storage data (`gs://`) and then
#'   resolve their values to the path of their local copy.
#'
#' @return List with configuration values
#'
#' @export
config <- function(local_gs = "gs") {

  # add any command line values passed to the R script into the extra_config
  # (this is used when CloudML passes arguments during hyperparameter turning)
  #
  # TODO: forward these args in deploy.py and pick out args after --
  #
  cmd_args <- commandArgs(trailingOnly = TRUE)

  # read the config file
  config <- config::get(file = "config.yml")

  # merge extra config
  config <- config::merge(config, .globals$extra_config)

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


# set extra config to be used for `cloudml::config()`
set_extra_config <- function(extra_config) {
  .globals$extra_config <- extra_config
}




