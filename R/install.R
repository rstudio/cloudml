#' Install Cloud ML Tools
#'
#' Installs all required Google Cloud ML tools, currently, the Cloud SDK.
#'
#' @export
cloudml_install <- function() {
  if (Sys.info()["sysname"] != "Darwin")
    stop("Currently, only OS X installation is supported.")

  cloudsdk_url <- "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/"
  cloudsdk_tar <- "google-cloud-sdk-178.0.0-darwin-x86_64.tar.gz"

  cloudsdk_dir <- "~/google-cloud-sdk/"
  cloudsdk_path <- file.path(cloudsdk_dir, cloudsdk_tar)

  if (!dir.exists(cloudsdk_dir)) dir.create(cloudsdk_dir)

  download.file(
    file.path(cloudsdk_url, cloudsdk_tar),
    cloudsdk_path
  )
}
