# Helper for building command line arguments.
shell_quote <- function(text) {
  paste("\"", gsub("\"", "\\\\\"", text), "\"", sep = "")
}

ShellArgumentsBuilder <- function() {

  arguments_ <- character()

  self <- function(...) {

    dots <- list(...)

    # return arguments when nothing supplied
    if (length(dots) == 0)
      return(arguments_)

    # any 0-length entries imply we should ignore this
    n <- lapply(dots, length)
    if (any(n == 0))
      return(invisible(self))

    # flatten a potentially nested list
    flattened <- flatten_list(dots)
    if (length(flattened) == 0)
      return(arguments_)

    formatted <- do.call(sprintf, flattened)
    arguments_ <<- c(arguments_, shell_quote(formatted))
    invisible(self)
  }

  self
}

MLArgumentsBuilder <- function() {
  (ShellArgumentsBuilder()
   ("ml-engine"))
}
