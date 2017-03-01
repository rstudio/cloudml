

# filter passed to config::add_filter to inject additional configuration
# into calls to config::get and to resolve gs:// urls to local paths
# when not running on gcloud
config_filter <- function(extra_config) {

  force(extra_config)

  function(config) {

    # add any command line values passed to the R script into the extra_config
    # (this is used when CloudML passes arguments during hyperparameter turning)
    #
    # TODO: forward these args in deploy.py and pick out args after --
    #
    cmd_args <- commandArgs(trailingOnly = TRUE)

    # merge the extra config with the provided config
    config <- config::merge(config, extra_config)

    # resolve gs:// urls (copy them locally if we aren't running on gcloud)
    resolve_gs_data <- function(value) {
      if (is.list(value) && length(value) > 0)
        lapply(value, resolve_gs_data)
      else if (is_gs_uri(value))
        gs_data(value)
      else
        value
    }
    config <- lapply(config, resolve_gs_data)

    # return the filtered config
    config
  }
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
