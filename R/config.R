

#' Get the currently active CloudML configuration
#'
#' @return R list with active configuration values.
#'
#' @details The `config.yml` contains various configuration values. These values
#'   can be distinct depending on whether execution is taking place on Google
#'   Cloud or in a local context.
#'
#'   When running on Google Cloud the name of the configuration will always be
#'   "gcloud". When running locally it will be "default" unless another
#'   named configuration is made active.
#'
#' @seealso [config::get()].
#'
#' @export
config <- function() {

  # get the current config
  config <- config::get()

  # merge any additionally provided config values
  config::merge(config, .globals$config_values)
}


with_config <- function(config_name, config_values, expr) {

  # inject R_ACTIVE_CONFIG
  if (!is.null(config_name)) {
    oldConfig <- Sys.getenv("R_ACTIVE_CONFIG", unset = NA)
    Sys.setenv(R_ACTIVE_CONFIG = config_name)
    if (!is.na(oldConfig))
      on.exit(Sys.setenv(R_ACTIVE_CONFIG = oldConfig), add = TRUE)
  }

  # inject additional values
  .globals$config_values <- config_values
  on.exit(.globals$config_values <- NULL, add = TRUE)

  # evaluate the expression
  force(expr)
}



resolve_config <- function(key,
                           value,
                           config,
                           config_path)
{
  # attempt to resolve 'key' as a child of node
  # 'value' in configuration 'config'
  configuration <- config::get(
    value  = value,
    config = config,
    file   = config_path
  )

  setting <- configuration[[key]]
  if (!is.null(setting))
    return(setting)

  # if that fails, attempt to resolve as a top-level
  # child for configuration 'config'
  config::get(
    value  = key,
    config = config,
    file   = config_path
  )
}
