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
    function() file.path(gcloud_path_default(), "bin/gcloud")
  )

  if (.Platform$OS.type == "windows") {
    appdata <- normalizePath(Sys.getenv("localappdata"), winslash = "/")
    win_path <- file.path(appdata, "Google/Cloud SDK/google-cloud-sdk/bin/gcloud")
    if (file.exists(win_path))
      return(file.path(appdata, "Google/\"Cloud SDK\"/google-cloud-sdk/bin/gcloud"))
  }

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
#' @param version Version of the Google Cloud SDK to be installed.
#'
#' @importFrom utils untar
gcloud_install <- function(version = "180.0.1") {
  if (file_test("-d", gcloud_path_default())) {
    message("SDK already installed.")
    return(invisible(NULL))
  }

  if (.Platform$OS.type != "unix") {
    stop("Currently, unix installations are only supported.")
  }

  if (Sys.info()["sysname"] == "Darwin")
    sysname <- "darwin"
  else
    sysname <- "linux"

  cloudsdk_url <- "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/"
  cloudsdk_tar <- paste0("google-cloud-sdk-", version, "-", sysname, "-x86_64.tar.gz")

  download_dir <- tempdir()
  download_file <- file.path(download_dir, cloudsdk_tar)

  if (!file_test("-d", download_dir)) dir.create(download_dir)

  download.file(
    file.path(cloudsdk_url, cloudsdk_tar),
    download_file
  )

  extract_dir <- "~/"
  untar(tarfile = download_file,
        exdir = extract_dir,
        tar = "internal")
}
