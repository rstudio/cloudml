
#' Read the configuration for a CloudML application
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
config <- function(config = NULL, local_gs = "local/gs") {

  # read the config file
  if (!is.null(config))
    config <- config::get(config = config, file = "config.yml")
  else
    config <- config::get(file = "config.yml")

  # merge overlay
  config <- config::merge(config, .globals$overlay)

  # merge parsed command line arguments
  clargs <- tensorflow::parse_arguments()
  config <- config::merge(config, clargs)

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
set_overlay <- function(overlay) {
  .globals$overlay <- overlay
}




