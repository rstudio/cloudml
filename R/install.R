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

  download_dir <- tempdir()
  download_file <- file.path(download_dir, cloudsdk_tar)

  if (!dir.exists(download_dir)) dir.create(download_dir)

  download.file(
    file.path(cloudsdk_url, cloudsdk_tar),
    download_file
  )

  extract_dir <- "~/"
  untar(tarfile = download_file,
        exdir = extract_dir,
        tar = "internal")
}

#' Path to the Google Cloud SDK
#'
#' Retrieves the path to the Google Cloud SDK.
#'
#' @internal
#' @export
cloudml_sdk_dir <- function() {
  "~/google-cloud-sdk"
}
