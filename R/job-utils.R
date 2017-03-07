cloudml_job <- function(class,
                        job_name,
                        job_dir)
{
  job <- list(
    job_name = job_name,
    job_dir  = job_dir
  )

  class(job) <- c(
    sprintf("cloudml_job_%s", class),
    "cloudml_job"
  )

  register_job(job)
  job
}

as.cloudml_job <- function(x) {
  UseMethod("as.cloudml_job")
}

#' @export
as.cloudml_job.character <- function(x) {
  resolve_job(x)
}

#' @export
as.cloudml_job.cloudml_job <- function(x) {
  x
}

job_name <- function(x, ...) {
  UseMethod("job_name")
}

#' @export
job_name.cloudml_job <- function(x, ...) {
  x$job_name
}

#' @export
job_name.character <- function(x, ...) {
  x
}

job_dir <- function(x, ...) {
  UseMethod("job_dir")
}

#' @export
job_dir.cloudml_job <- function(x, ...) {
  x$job_dir
}

#' @export
job_dir.character <- function(x, ...) {
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

#' Generate a Unique Job Directory
#'
#' Generate a job directory (as a relative path). Useful for
#' deployments when you want model artefacts to be confined to
#' a unique directory.
#'
#' @param prefix
#'   The prefix to be used for the job directory.
#'
#' @export
unique_job_dir <- function(prefix = "") {
  sprintf(
    "%s/%s",
    prefix,
    timestamp_string()
  )
}

