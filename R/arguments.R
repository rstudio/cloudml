# Helper for building command line arguments.
shell_quote <- function(text) {
  paste("\"", gsub("\"", "\\\\\"", text), "\"", sep = "")
}

ShellArgumentsBuilder <- function() {

  arguments_ <- character()

  self <- function(...) {

    dots <- unlist(list(...))
    if (length(dots) == 0)
      return(arguments_)

    if (length(dots) == 1 && is.null(dots[[1]]))
      return(invisible(self))

    arguments_ <<- c(arguments_, shell_quote(sprintf(...)))
    invisible(self)
  }

  self
}

