# Helper for building command line arguments.
shell_quote <- function(text) {
  paste("\"", gsub("\"", "\\\\\"", text), "\"", sep = "")
}

ShellArgumentsBuilder <- function() {

  arguments_ <- character()

  self <- function(...) {

    dots <- list(...)

    # handle 'NULL' specially
    if (length(dots) == 1 && is.null(dots[[1]]))
      return(invisible(self))

    # return arguments when nothing supplied
    if (length(dots) == 0)
      return(arguments_)

    # flatten a potentially nested list
    flattened <- as.list(unlist(list(...)))
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
