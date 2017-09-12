# Helper for building command line arguments.
shell_quote <- function(text) {
  paste("\"", gsub("\"", "\\\\\"", text), "\"", sep = "")
}

ShellArgumentsBuilder <- function() {

  .arguments <- character()

  # define the builder
  builder <- function(...) {

    dots <- list(...)

    # return arguments when nothing supplied
    if (length(dots) == 0)
      return(.arguments)

    # any 0-length entries imply we should ignore this
    n <- lapply(dots, length)
    if (any(n == 0))
      return(invisible(builder))

    # flatten a potentially nested list
    flattened <- flatten_list(dots)
    if (length(flattened) == 0)
      return(.arguments)

    formatted <- do.call(sprintf, flattened)
    .arguments <<- c(.arguments, shell_quote(formatted))
    invisible(builder)
  }

  # prepend project + account information
  conf <- gcloud_config()
  (builder
    ("--project")
    (conf$project)
    ("--account")
    (conf$account))

  # return our builder object
  builder
}

MLArgumentsBuilder <- function() {
  (ShellArgumentsBuilder()
   ("ml-engine"))
}
