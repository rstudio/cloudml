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
#' @export
gcloud_install <- function(overwrite = "prompt") {

  if (.Platform$OS.type != "unix") {
    stop("Currently, unix installations are only supported.")
  }

  if (Sys.info()["sysname"] == "Darwin")
    sysname <- "darwin"
  else
    sysname <- "linux"

  # download the interactive installer script and mark it executable
  message("Downloading Google Cloud SDK...")
  install_script <- tempfile("install_google_cloud_sdk-", fileext = ".bash")
  download.file("https://dl.google.com/dl/cloudsdk/channels/rapid/install_google_cloud_sdk.bash",
                install_script)
  Sys.chmod(install_script, "755")

  # get gcloud path
  gcloud_path <- gcloud_path_default()

  # if in rstudio then continue in the terminal
  if (have_rstudio_terminal()) {

    readline("Installation of the Google Cloud SDK will continue in a terminal [OK]: ")
    install_args <- paste(shQuote(c(install_script,
                              paste0("--install-dir=",
                                     path.expand(dirname(gcloud_path))))),
                          collapse = " ")
    terminal_command <- paste(install_args, "&&", "gcloud", "init")
    gcloud_terminal(terminal_command, clear = TRUE)

  } else {

    # remove existing installation if necessary
    if (utils::file_test("-d", gcloud_path)) {
      message(paste("Google Cloud SDK already installed at", gcloud_path))
      if (identical(overwrite, "prompt")) {
        cat("\n")
        prompt <- readline("Remove existing installation of SDK? [Y/n]: ")
        if (nzchar(prompt) && tolower(prompt) != 'y')
          return(invisible(NULL))
        else {
          message("Removing existing installation of SDK")
          unlink(gcloud_path, recursive = TRUE)
        }
      } else if (identical(overwrite, TRUE)) {
        message("Removing existing installation of SDK")
        unlink(gcloud_path, recursive = TRUE)
      } else {
        return(invisible(NULL))
      }
    }

    # build arguments to sdk
    args <- c(paste0("--install-dir=", dirname(path.expand(gcloud_path))),
              "--disable-prompts")

    # execute with processx
    message("Running Google Cloud SDK Installation...")
    result <- processx::run(install_script, args, echo = TRUE)

    # prompt to run gcloud init
    message("Google Cloud SDK tools installed at ", gcloud_path)
    cat("\n")
    message("IMPORTANT: To complete the installation, launch a terminal and execute the following:")
    cat("\n")
    message("  $ ", file.path(path.expand(gcloud_path), "bin/gcloud init"))
    cat("\n")
  }

  invisible(NULL)
}
