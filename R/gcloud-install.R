# Discover Path to Google Cloud SDK
#
# Discover the paths of the `gcloud` and `gsutil` executables.
#
# @details
# The path to the `gcloud` executable can be explicitly
# specified, using the `GCLOUD_BINARY_PATH` environment
# variable, or the `gcloud.binary.path` \R option.
#
# The path to the `gsutil` executable can be explicitly
# specified, using the `GSUTIL_BINARY_PATH` environment
# variable, or the `gsutil.binary.path` \R option.
#
# When none of the above are set, locations will instead be
# discovered either on the system `PATH`, or by looking
# in the default folders used for the Google Cloud SDK
# installation.
#
# @name gcloud-paths
# @keywords internal
gcloud_binary <- function() {

  user_path <- user_setting("gcloud.binary.path")
  if (!is.null(user_path))
    return(normalizePath(user_path))

  if (.Platform$OS.type == "windows") {
    appdata <- normalizePath(Sys.getenv("localappdata"), winslash = "/")
    win_path <- file.path(appdata, "Google/Cloud SDK/google-cloud-sdk/bin/gcloud.cmd")

    candidates <- c(
      function() file.path(appdata, "Google/Cloud SDK/google-cloud-sdk/bin/gcloud.cmd"),
      function() file.path(Sys.getenv("ProgramFiles"), "/Google/Cloud SDK/google-cloud-sdk/bin/gcloud.cmd"),
      function() file.path(Sys.getenv("ProgramFiles(x86)"), "/Google/Cloud SDK/google-cloud-sdk/bin/gcloud.cmd")
    )
  } else {
    candidates <- c(
      function() Sys.which("gcloud"),
      function() "~/google-cloud-sdk/bin/gcloud",
      function() file.path(gcloud_binary_default(), "bin/gcloud")
    )
  }

  for (candidate in candidates)
    if (file.exists(candidate()))
      return(normalizePath(candidate()))

  stop("failed to find 'gcloud' binary")
}

gcloud_binary_default <- function() {
  Sys.getenv("GCLOUD_INSTALL_PATH", "~/google-cloud-sdk")
}

#' Install the Google Cloud SDK
#'
#' Installs the Google Cloud SDK which enables CloudML operations.
#'
#' @param update Attempt to update an existing installation.
#'
#' @export
gcloud_install <- function(update = TRUE) {

  # if we have an existing installation and update is FALSE then abort
  if (gcloud_installed() && !update)
    return(invisible(NULL))

  if (identical(.Platform$OS.type, "windows"))
    gcloud_install_windows()
  else if (identical(.Platform$OS.type, "unix"))
    gcloud_install_unix()
  else
    stop("This platform is not supported by the Google Cloud SDK")
}

gcloud_install_unix <- function() {

  # download the interactive installer script and mark it executable
  message("Downloading Google Cloud SDK...")
  install_script <- tempfile("install_google_cloud_sdk-", fileext = ".bash")
  utils::download.file("https://dl.google.com/dl/cloudsdk/channels/rapid/install_google_cloud_sdk.bash",
                       install_script)
  Sys.chmod(install_script, "755")

  # get gcloud path
  gcloud_binary <- gcloud_binary_default()

  # if in rstudio then continue in the terminal
  if (have_rstudio_terminal()) {

    readline("Installation of the Google Cloud SDK will continue in a terminal [OK]: ")
    install_args <- paste(shQuote(c(install_script,
                              paste0("--install-dir=",
                                     path.expand(dirname(gcloud_binary))))),
                          collapse = " ")
    terminal_command <- paste(install_args, "&&", "gcloud", "init")
    gcloud_terminal(terminal_command, clear = TRUE)

  } else {

    # remove existing installation if necessary
    if (utils::file_test("-d", gcloud_binary)) {
      message(paste("Google Cloud SDK already installed at", gcloud_binary))
      cat("\n")
      prompt <- readline("Remove existing installation of SDK? [Y/n]: ")
      if (nzchar(prompt) && tolower(prompt) != 'y')
        return(invisible(NULL))
      else {
        message("Removing existing installation of SDK")
        unlink(gcloud_binary, recursive = TRUE)
      }
    }

    # build arguments to sdk
    args <- c(paste0("--install-dir=", dirname(path.expand(gcloud_binary))),
              "--disable-prompts")

    # execute with processx
    message("Running Google Cloud SDK Installation...")
    result <- processx::run(install_script, args, echo = TRUE)

    # prompt to run gcloud init
    message("Google Cloud SDK tools installed at ", gcloud_binary)
    cat("\n")
    message("IMPORTANT: To complete the installation, launch a terminal and execute the following:")
    cat("\n")
    message("  $ ", file.path(path.expand(gcloud_binary), "bin/gcloud init"))
    cat("\n")
  }

  invisible(NULL)
}


gcloud_install_windows <- function() {

  message("Downloading Google Cloud SDK...")
  installer <- tempfile("GoogleCloudSDKInstaller-", fileext = ".exe")
  utils::download.file("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe",
                       installer,
                       mode = "wb")

  shell.exec(installer)

  invisible(NULL)
}

# Checks the Google Cloud SDK Install
gcloud_installed <- function() {
  have_sdk <- !is.null(tryCatch(gcloud_binary(), error = function(e) NULL))
  if (have_sdk)
    gcloud_default_account() != "(unset)"
  else
    FALSE
}
