#' Install the Google Cloud SDK
#'
#' Installs the Google Cloud SDK which enables CloudML operations.
#'
#' @export
sdk_install <- function() {
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

#' Retrieve Google Cloud SDK Path
#'
#' Retrieves the path to the Google Cloud SDK.
#'
#' @export
sdk_dir <- function() {
  "~/google-cloud-sdk"
}

#' Trigger Google Cloud SDK Command
#'
#' Triggers a Google Cloud SDK command.
#'
#' @param ... Parameters to use with 'gcloud'.
#'
#' @export
sdk_command <- function(...) {
  params <- list(...)
  gcloud <- file.path(sdk_dir(), "bin", "gcloud")

  system2(
    normalizePath(gcloud),
    params
  )
}

#' Login to Google Cloud SDK
#'
#' Login to Google Cloud SDK to enable CloudML operations.
#'
#' @export
sdk_login <- function() {
  sdk_command("auth", "application-default", "login")
}

#' Config the Google Cloud SDK
#'
#' Config the Google Cloud SDK to enable CloudML operations.
#'
#' @param account The account to use in subsequent Google Cloud SDK operations.
#'   Usually the email associated to the account.
#' @param project The project to use in subsequent Google Cloud SDK operations.
#'
#' @export
sdk_config <- function(account, project) {
  sdk_command("config", "set", "core/account", account)
  sdk_command("config", "set", "core/project", project)
}
