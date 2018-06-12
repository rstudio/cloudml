


#' Create an RStudio terminal with access to the Google Cloud SDK
#'
#' @param command Command to send to terminal
#' @param clear Clear terminal buffer
#'
#' @return Terminal id (invisibly)
#'
#' @family Google Cloud SDK functions
#' @export
gcloud_terminal <- function(command = NULL, clear = FALSE) {

  if (!have_rstudio_terminal())
    stop("The cloudml_terminal function requires RStudio v1.1 or higher")

  init_terminal <- function(id) {
    if (clear)
      rstudioapi::terminalClear(id)
    if (!is.null(command)) {
      terminal_context <- rstudioapi::terminalContext(id)

      windows_terminal <- .Platform$OS.type == "windows" &&
        !identical(terminal_context$shell, "Git Bash")

      if (windows_terminal) {
        os_return   <- "\r\n"
        os_collapse <-  " & "
      } else {
        os_return   <- "\n"
        os_collapse <- " ; "
      }

      if (length(command) > 0) {
        command <- paste(
          command,
          collapse = os_collapse
        )
      }

      rstudioapi::terminalSend(id, paste0(command, os_return))
    }
  }

  # check for existing gcloud sdk terminal and use it if not busy
  gcloud_sdk_terminal <- "Google Cloud"
  terminals <- rstudioapi::terminalList()
  gcloud_terminals <- c()
  for (terminal in terminals) {
    terminal <- rstudioapi::terminalContext(terminal)
    if (startsWith(terminal$caption, gcloud_sdk_terminal)) {
      gcloud_terminals <- c(gcloud_terminals, terminal$caption)
      id <- terminal$handle
      if (!rstudioapi::terminalBusy(id)) {
        rstudioapi::terminalActivate(id)
        init_terminal(id)
        return(invisible(id))
      }
    }
  }

  gcloud_path <- tryCatch({
    gcloud_binary()
  }, error = function(e) {
    ""
  })

  # launch terminal with cloud sdk on the PATH
  withr::with_path(gcloud_path, {

    if (length(gcloud_terminals) > 0) {

      # discover existing instances of Google Cloud terminals and choose an
      # index greater than the largest one
      terminal_indexes <- regmatches(gcloud_terminals,
                                     regexpr("\\(\\d+\\)",gcloud_terminals))
      if (length(terminal_indexes) > 0) {
        terminal_indexes <- sub("\\(", "", terminal_indexes)
        terminal_indexes <- sub("\\)", "", terminal_indexes)
        terminal_indexes <- as.integer(terminal_indexes)
        next_index <- max(terminal_indexes) + 1
      } else {
        next_index <- 2
      }
      gcloud_sdk_terminal <- sprintf("%s (%d)", gcloud_sdk_terminal, next_index)
    }

    if (packageVersion("rstudioapi") > "0.7.0-9000" &&
        .Platform$OS.type == "windows" &&
        rstudioapi::getVersion() >= "1.2.696") {
      id <- rstudioapi::terminalCreate(gcloud_sdk_terminal, shellType = "win-cmd")
    }
    else {
      id <- rstudioapi::terminalCreate(gcloud_sdk_terminal)
    }

    terminal_shell <- rstudioapi::terminalContext(id)$shell
    if (identical(tolower(.Platform$OS.type), "windows") &&
        !startsWith(terminal_shell, "Command Prompt")) {
      warning(
        "'cloudml' requires RStudio's terminal to be configured to use the 'Command Prompt' ",
        "but it's currently configured to use '", terminal_shell, "'. You can change ",
        "this setting from Tools - Global Options - Terminal."
      )
    }

    init_terminal(id)
  })

  # return the terminal id
  invisible(id)
}


#' Initialize the Google Cloud SDK
#'
#' @family Google Cloud SDK functions
#' @export
gcloud_init <- function() {
  if (have_rstudio_terminal()) {
    gcloud_terminal(
      paste(
        shQuote(gcloud_binary()),
        "init"
      )
    )
  } else {
    gcloud_init_message()
  }
}

gcloud_init_message <- function() {
  message("To initialize the Google Cloud SDK, launch a terminal and execute the following:")
  cat("\n")
  message("  $ ", gcloud_binary(), " init\n")
}

have_rstudio_terminal <- function() {
  rstudioapi::hasFun("terminalCreate")
}


