cloudml_job <- function(class,
                        app_dir,
                        job_name,
                        job_dir)
{
  object <- list(
    app_dir  = app_dir,
    job_name = job_name,
    job_dir  = job_dir
  )

  class(object) <- c(
    sprintf("cloudml_job_%s", class),
    "cloudml_job"
  )

  object
}

job_name <- function(x, ...) {
  UseMethod("job_name")
}

job_name.cloudml_job <- function(x, ...) {
  x$job_name
}

job_name.character <- function(x, ...) {
  x
}

job_dir <- function(x, ...) {
  UseMethod("job_dir")
}

job_dir.cloudml_job <- function(x, ...) {
  x$job_dir
}

job_dir.character <- function(x, ...) {
  x
}

app_dir <- function(x, ...) {
  UseMethod("app_dir")
}

app_dir.cloudml_app <- function(x, ...) {
  x$app_dir
}

app_dir.character <- function(x, ...) {
  x
}


print.cloudml_job <- function(x, ...) {
  header <- "<cloudml job>"
  fields <- enumerate(x, function(key, val) {
    paste(key, val, sep = ": ")
  })

  text <- paste(
    header,
    paste("  ", fields, sep = "", collapse = "\n"),
    sep = "\n"
  )

  cat(text, sep = "\n")

  x
}

#' Generate a Job Directory
#'
#' Generate a job directory (as a relative path). Useful for
#' deployments when you want model artefacts to be confined to
#' a unique directory.
#'
#' @param prefix
#'   The prefix to be used for the job directory.
#'
#' @export
create_job_dir <- function(prefix = "jobs") {
  sprintf(
    "%s/%s_%i",
    prefix,
    format(Sys.time(), "%Y%m%d"),
    as.integer(Sys.time())
  )
}

