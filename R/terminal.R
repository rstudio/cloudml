


#' Create an RStudio terminal with access to the Google Cloud SDK
#'
#' @param command Command to send to terminal
#'
#' @return Terminal id (invisibly)
#'
#' @export
gcloud_terminal <- function(command = NULL) {

  if (!have_rstudio_terminal())
    stop("The cloudml_terminal function requires RStudio v1.1 or higher")

  # check for existing gcloud sdk terminal and use it if found
  gcloud_sdk_terminal <- "Google Cloud SDK"
  terminals <- rstudioapi::terminalList()
  for (terminal in terminals) {
    terminal <- rstudioapi::terminalContext(terminal)
    if (terminal$caption == gcloud_sdk_terminal) {
      id <- terminal$handle
      rstudioapi::terminalActivate(id)
      if (!is.null(command))
        rstudioapi::terminalSend(id, paste0(command, "\n"))
      return(invisible(id))
    }
  }


  # launch terminal with cloud sdk on the PATH
  withr::with_path(gcloud_path(), {
    id <- rstudioapi::terminalCreate("Google Cloud SDK")
    if (!is.null(command))
      rstudioapi::terminalSend(id, paste0(command, "\n"))
  })

  # return the terminal id
  invisible(id)
}


#' Initialize the Google Cloud SDK
#'
#' @export
gcloud_init <- function() {
  if (have_rstudio_terminal()) {
    gcloud_terminal("gcloud init")
  } else {
    cat("To intialize the Google Cloud SDK, launch a terminal and execute the following:\n\n")
    cat(gcloud_path(), "init\n\n")
  }
}



have_rstudio_terminal <- function() {
  rstudioapi::hasFun("terminalCreate")
}


