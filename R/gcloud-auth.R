#' Login to Google Cloud
#'
#' Login to Google Cloud using the Google Cloud SDK.
#'
#' @export
gcloud_login <- function() {
  gcloud_exec("auth", "application-default", "login")
}
