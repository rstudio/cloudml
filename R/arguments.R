# Helper for building command line arguments.
Arguments <- function() {
  arguments_ <- character()
  self <- function(...) {
    dots <- list(...)
    if (length(dots) == 0)
      return(arguments_)
    arguments_ <<- c(arguments_, sprintf(...))
    invisible(self)
  }
  self
}
