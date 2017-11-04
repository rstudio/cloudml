# execute a gcloud command
gexec <- function(command,
                  args = character())
{
  result <- processx::run(
    commandline = paste(
      command,
      paste(shell_quote(args), collapse = " ")
    ),
    echo = TRUE
  )

  if (result$status != 0) {
    output <- c(
      sprintf("ERROR: gcloud invocation failed [exit status %i]", status),

      "",
      "[command]",
      pretty,

      "",
      "[output]",
      if (length(result$stdout))
        paste(result$stdout, collapse = "\n")
      else
        "<none available>",

      "",
      "[errmsg]",
      if (length(result$stderr))
        paste(result$stderr, collapse = "\n")
      else
        "<none available>"
    )

    pasted <- paste(output, collapse = "\n")
    message(pasted)

    stop("error invoking 'gcloud' executable", call. = FALSE)
  }

  invisible(result)
}

#' Executes a Google Cloud Command
#'
#' Executes a Google Cloud command with the given parameters.
#'
#' @param ... Parameters to use specified based on position.
#' @param args Parameters to use specified as a list.
#'
#' @export
gcloud_exec <- function(..., args = NULL)
{
  if (is.null(args))
    args <- list(...)

  gexec(
    normalizePath(gcloud_path()),
    args
  )
}
