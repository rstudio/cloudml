cloudml_config_active <- function() {
  Sys.getenv("R_CONFIG_ACTIVE", unset = "default")
}
