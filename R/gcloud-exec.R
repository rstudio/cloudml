# execute a gcloud command
gexec <- function(command,
                  args = character(),
                  echo = TRUE)
{
  quoted_args <- args
  if (.Platform$OS.type != "windows")
    quoted_args <- shell_quote(args)

  result <- processx::run(
    commandline = paste(
      command,
      paste(quoted_args, collapse = " ")
    ),
    echo = echo
  )

  if (result$status != 0) {
    output <- c(
      sprintf("ERROR: gcloud invocation failed [exit status %i]", result$status),

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
#' @param echo Echo command output to console
#'
gcloud_exec <- function(..., args = NULL, echo = FALSE)
{
  if (is.null(args))
    args <- list(...)

  command <- gcloud_path()
  if (.Platform$OS.type != "windows")
    command <- shQuote(normalizePath(gcloud_path()))

  gexec(
    command,
    args,
    echo
  )
}
