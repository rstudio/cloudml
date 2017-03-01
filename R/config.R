cloudml_config_active <- function() {
  Sys.getenv("R_CONFIG_ACTIVE", unset = "default")
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
