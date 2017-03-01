# Helper for building command line arguments.
shell_quote <- function(text) {
  paste("\"", gsub("\"", "\\\\\"", text), "\"", sep = "")
}

ShellArgumentsBuilder <- function() {

  arguments_ <- character()

  self <- function(...) {

    # flatten a potentially nested list
    dots <- as.list(unlist(list(...)))
    if (length(dots) == 0)
      return(arguments_)

    if (length(dots) == 1 && is.null(dots[[1]]))
      return(invisible(self))

    formatted <- do.call(sprintf, dots)
    arguments_ <<- c(arguments_, shell_quote(formatted))
    invisible(self)
  }

  self
}

