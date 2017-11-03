# execute a gcloud command
gexec <- function(command,
                  args = character(),
                  stdout = TRUE,
                  stderr = TRUE,
                  ...)
{
  # 'system2' will report a warning if a command is executed but
  # returns with a non-zero status. we handle that explicitly so we
  # suppress the R warning here and print an equivalent later
  suppressWarnings(
    result <- system2(
      command = command,
      args    = shell_quote(args),
      stdout  = stdout,
      stderr  = stderr,
      ...
    )
  )

  # if we've interned stdout / stderr, then we need to
  # grab the return status and report output separately
  if (isTRUE(stdout) || isTRUE(stderr)) {
    status <- attr(result, "status")
    if (!is.null(status)) {
      errmsg <- attr(result, "errmsg")

      pretty <- paste(
        shell_quote(command),
        paste(
          "",
          shell_quote(args),
          sep = "\t",
          collapse = "\n"
        ),
        sep = "\n"
      )

      output <- c(
        sprintf("ERROR: gcloud invocation failed [exit status %i]", status),

        "",
        "[command]",
        pretty,

        "",
        "[output]",
        if (length(result))
          paste(result, collapse = "\n")
        else
          "<none available>",

        "",
        "[errmsg]",
        if (!is.null(errmsg))
          paste(errmsg, collapse = "\n")
        else
          "<none available>"
      )

      pasted <- paste(output, collapse = "\n")
      message(pasted)

      stop("error invoking 'gcloud' executable", call. = FALSE)
    }
  }

  result
}

#' Executes a Google Cloud Command
#'
#' Executes a Google Cloud command with the given parameters.
#'
#' @param ... Parameters to use specified based on position.
#' @param args Parameters to use specified as a list.
#'
#' @export
gcloud_exec <- function(...,
                        args = NULL,
                        stdout = TRUE,
                        stderr = TRUE)
{
  if (is.null(args))
    args <- list(...)

  gexec(
    normalizePath(gcloud_path()),
    args,
    stdout = stdout,
    stderr = stderr
  )
}
