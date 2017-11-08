#' Discover Path to Google Cloud SDK
#'
#' Discover the paths of the `gcloud` and `gsutil` executables.
#'
#' @details
#' The path to the `gcloud` executable can be explicitly
#' specified, using the `GCLOUD_BINARY_PATH` environment
#' variable, or the `gcloud.binary.path` \R option.
#'
#' The path to the `gsutil` executable can be explicitly
#' specified, using the `GSUTIL_BINARY_PATH` environment
#' variable, or the `gsutil.binary.path` \R option.
#'
#' When none of the above are set, locations will instead be
#' discovered either on the system `PATH`, or by looking
#' in the default folders used for the Google Cloud SDK
#' installation.
#'
#' @name gcloud-paths
#' @keywords internal
#' @export
gcloud_path <- function() {

  user_path <- user_setting("gcloud.binary.path")
  if (!is.null(user_path))
    return(normalizePath(user_path))

  candidates <- c(
    function() Sys.which("gcloud"),
    function() "~/google-cloud-sdk/bin/gcloud",
    function() file.path(Sys.getenv("GCLOUD_INSTALL_PATH", "~/google-cloud-sdk"), "bin/gcloud")
  )

  for (candidate in candidates)
    if (file.exists(candidate()))
      return(normalizePath(candidate()))

  stop("failed to find 'gcloud' binary")
}

gcloud_path_default <- function() {
  Sys.getenv("GCLOUD_INSTALL_PATH", "~/google-cloud-sdk")
}

#' Install the Google Cloud SDK
#'
#' Installs the Google Cloud SDK which enables CloudML operations.
#'
#' @export
gcloud_install <- function(version = "178.0.0") {
  if (dir.exists(gcloud_path_default())) {
    message("SDK already installed.")
    return(invisible(NULL))
  }

  if (Sys.info()["sysname"] != "Darwin")
    stop("Currently, only OS X installation is supported.")

  cloudsdk_url <- "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/"
  cloudsdk_tar <- paste0("google-cloud-sdk-", version, "-darwin-x86_64.tar.gz")

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
