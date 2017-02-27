# Helper for building command line arguments.
shell_quote <- function(text) {
  paste("\"", gsub("\"", "\\\\\"", text), "\"", sep = "")
}

ShellArgumentsBuilder <- function() {

  arguments_ <- character()

  self <- function(...) {

    dots <- list(...)
    if (length(dots) == 0)
      return(arguments_)

    arguments_ <<- c(arguments_, shell_quote(sprintf(...)))
    invisible(self)
  }

  self
}

