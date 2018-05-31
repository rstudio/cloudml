# execute a gcloud command
gexec <- function(command,
                  args = character(),
                  echo = TRUE,
                  throws = TRUE)
{
  command <- normalizePath(command, mustWork = FALSE)

  if (.Platform$OS.type == "windows") {
    args <- c("/c", command, args)
    command <- "cmd"
  }

  result <- processx::run(
    command = command,
    args = as.character(args),
    echo = echo,
    error_on_status = FALSE
  )

  if (result$status != 0 && throws) {
    output <- c(
      sprintf("ERROR: gcloud invocation failed [exit status %i]", result$status),

      "",
      "[command]",
      paste(
        command,
        paste(args, collapse = " ")
      ),

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
    stop(pasted, call. = FALSE)
  }

  invisible(result)
}

#' Executes a Google Cloud Command
#'
#' Executes a Google Cloud command with the given parameters.
#'
#' @param ... Parameters to use specified based on position.
#' @param args Parameters to use specified as a list.
#' @param echo Echo command output to console.
#'
#' @examples
#' \dontrun{
#' gcloud_exec("help", "info")
#' }
#' @keywords internal
#' @export
gcloud_exec <- function(..., args = NULL, echo = TRUE)
{
  if (is.null(args))
    args <- list(...)

  gexec(
    gcloud_binary(),
    args,
    echo
  )
}
