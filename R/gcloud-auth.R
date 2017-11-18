#' Login to Google Cloud
#'
#' Login to Google Cloud using the Google Cloud SDK.
#'
gcloud_login <- function() {
  config <- gcloud_config()
  gcloud_exec("config", "set", "core/account", config$account)
  gcloud_exec("config", "set", "core/project", config$project)

  gcloud_exec("auth", "application-default", "login")
}
