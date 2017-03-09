
#' Train a model using Cloud ML
#'
#' Upload a TensorFlow application to Google Cloud, and use that application to
#' train a model.
#'
#' @param application
#'   The path to a TensorFlow application. Defaults to
#'   the current working directory.
#'
#' @param config
#'   The name of the configuration to be used. Defaults to
#'   the `"cloudml"` configuration.
#'
#' @param ...
#'   Named arguments, used to supply runtime configuration
#'   settings to your TensorFlow application. When
#'   [cloudml::config()] is called, these values will effectively
#'   be overlayed on top of the configuration requested.
#'
#' @seealso [job_describe()], [job_collect()], [job_cancel()]
#'
#' @examples \dontrun{
#' library(cloudml)
#' job <- cloudml_train()
#' job_status(job)
#' job_collect(job)
#' }
#' @export
cloudml_train <- function(application = getwd(),
                          config      = "cloudml",
                          ...)
{
  Sys.setenv(CLOUDML_EXECUTION_ENVIRONMENT = "gcloud")
  on.exit(Sys.unsetenv("CLOUDML_EXECUTION_ENVIRONMENT"), add = TRUE)

  # prepare application for deployment
  application <- scope_deployment(application)

  # resolve runtime configuration and serialize
  # within the application's cloudml directory
  overlay <- resolve_train_overlay(application, list(...), config)
  ensure_directory("cloudml")
  saveRDS(overlay, file = "cloudml/overlay.rds")

  # generate setup.py
  scope_setup_py(application)

  # move to application's parent directory
  setwd(dirname(application))

  # generate deployment script
  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("submit")
                ("training")
                (overlay$job_name)
                ("--async")
                ("--package-path=%s", basename(application))
                ("--module-name=%s.cloudml.deploy", basename(application))
                ("--job-dir=%s", overlay$job_dir)
                ("--staging-bucket=%s", overlay$staging_bucket)
                ("--region=%s", overlay$region)
                ("--runtime-version=%s", overlay$runtime_version)
                ("--")
                ("--cloudml-entrypoint=%s", overlay$entrypoint)
                ("--cloudml-config=%s", config)
                ("--cloudml-environment=gcloud"))

  # submit job through command line interface
  output <- gexec(gcloud(), arguments(), stdout = TRUE, stderr = TRUE)

  # extract job id from output
  index <- grep("^jobId:", output)
  job_name <- substring(output[index], 8)

  # construct and register job object
  job <- cloudml_job(
    "train",
    job_name = job_name,
    job_dir  = job_dir
  )

  # inform user of successful job submission
  template <- c(
    "Job '%1$s' successfully submitted.",
    "",
    "Check status and collect output with:",
    "- job_status(\"%1$s\")",
    "- job_collect(\"%1$s\")"
  )

  rendered <- sprintf(paste(template, collapse = "\n"), job_name(job))

  # print stderr output from a 'describe' call (this gives the
  # user URLs that can be navigated to for more information)
  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("describe")
                (job_name))

  # write stdout, stderr separately (we only want to report
  # the data written to stderr here)
  sofile <- tempfile("stdout-")
  sefile <- tempfile("stderr-")
  output <- gexec(gcloud(), arguments(), stdout = sofile, stderr = sefile)
  stderr <- readChar(sefile, file.info(sefile)$size, TRUE)

  # write the generated messages to the console
  message(rendered)
  message(stderr)

  invisible(job)
}

#' Cancel a job
#'
#' Cancel a job.
#'
#' @inheritParams job_status
#'
#' @seealso [job_describe()], [job_collect()], [job_list()]
#'
#' @export
job_cancel <- function(job) {
  job <- as.cloudml_job(job)

  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("cancel")
                (job_name(job)))

  gexec(gcloud(), arguments())
}

#' @rdname job_status
#' @export
job_describe <- function(job) {
  job <- as.cloudml_job(job)

  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("describe")
                (job_name(job)))

  output <- gexec(gcloud(), arguments(), stdout = TRUE)

  # return as R list
  yaml::yaml.load(paste(output, collapse = "\n"))
}

#' List all jobs
#'
#' List existing Google Cloud ML jobs.
#'
#' @param filter
#'   Filter the set of jobs to be returned.
#'
#' @param limit
#'   The maximum number of resources to list. By default,
#'   all jobs will be listed.
#'
#' @param page_size
#'   Some services group resource list output into pages.
#'   This flag specifies the maximum number of resources per
#'   page. The default is determined by the service if it
#'   supports paging, otherwise it is unlimited (no paging).
#'
#' @param sort_by
#'   A comma-separated list of resource field key names to
#'   sort by. The default order is ascending. Prefix a field
#'   with `~` for descending order on that field.
#'
#' @param uri
#'   Print a list of resource URIs instead of the default
#'   output.
#'
#' @family job management
#'
#' @seealso [job_describe()], [job_collect()], [job_cancel()]
#'
#' @export
job_list <- function(filter    = NULL,
                     limit     = NULL,
                     page_size = NULL,
                     sort_by   = NULL,
                     uri       = FALSE)
{
  arguments <- (
    MLArgumentsBuilder()
    ("jobs")
    ("list")
    ("--filter=%s", filter)
    ("--limit=%i", as.integer(limit))
    ("--page-size=%i", as.integer(page_size))
    ("--sort-by=%s", sort_by)
    (if (uri) "--uri"))

  gexec(gcloud(), arguments())
}


#' @rdname job_status
#' @export
job_stream <- function(job,
                       polling_interval = 60,
                       task_name = NULL,
                       allow_multiline_logs = FALSE)
{
  job <- as.cloudml_job(job)

  arguments <- (
    MLArgumentsBuilder()
    ("jobs")
    ("stream-logs")
    ("--polling-interval=%i", as.integer(polling_interval))
    ("--task-name=%s", task_name))

  if (allow_multiline_logs)
    arguments("--allow-multiline-logs")

  gexec(gcloud(), arguments())
}

#' Get job information
#'
#' Get detailed information on a job and it's status. Stream
#' the log of a running job.
#'
#' @param job
#'   Either a `cloudml_job` object as returned by [cloudml_train()],
#'   or the name of a job.
#' @param polling_interval Polling interval for streamed output.
#' @param task_name
#'   If set, display only the logs for this particular task.
#' @param allow_multiline_logs
#'   Output multiline log messages as single records.
#'
#' @seealso [job_collect()], [job_cancel()], [job_list()]
#'
#' @export
job_status <- function(job) {
  job <- as.cloudml_job(job)

  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("describe")
                (job_name(job)))

  # request job description from gcloud
  output <- gexec(gcloud(), arguments(), stdout = TRUE, stderr = FALSE)

  # parse as YAML and return
  yaml::yaml.load(paste(output, collapse = "\n"))
}

#' Collect job output
#'
#' Collect the job outputs (e.g. fitted model) from a job.
#' If the job has not yet finished running, `job_collect()`
#' will block and wait until the job has finished.
#'
#' @inheritParams job_status
#'
#' @param destination
#'   The destination directory in which model outputs should
#'   be downloaded. Defaults to `jobs/cloudml`.
#'
#' @seealso [job_describe()], [job_cancel()], [job_list()]
#'
#' @export
job_collect <- function(job, destination = "jobs/cloudml") {
  job <- as.cloudml_job(job)
  id <- job_name(job)

  # get the job status
  status <- job_status(job)

  # if we're already done, attempt download of outputs
  if (status$state == "SUCCEEDED")
    return(job_download(job, destination))

  # if the job has failed, report error
  if (status$state == "FAILED") {
    fmt <- "job '%s' failed [state: %s]"
    stopf(fmt, id, status$state)
  }

  # otherwise, notify the user and begin polling
  fmt <- ">>> Job '%s' is currently running -- please wait..."
  printf(fmt, id)
  printf(">>> [state: %s]", status$state)

  # TODO: should we give up after a while? (user can always interrupt)
  repeat {

    # get the job status
    status <- job_status(job)

    # download outputs on success
    if (status$state == "SUCCEEDED")
      return(job_download(job, destination))

    # if the job has failed, report error
    if (status$state == "FAILED") {
      fmt <- "job '%s' failed [state: %s]"
      stopf(fmt, id, status$state)
    }

    # job isn't ready yet; sleep for a while and try again
    Sys.sleep(60)

  }

  stop("failed to receive job outputs")
}

job_download <- function(job, destination = "jobs/cloudml") {
  job <- as.cloudml_job(job)
  source <- job_dir(job)

  if (!is_gs_uri(source)) {
    fmt <- "job directory '%s' is not a Google Storage URI"
    stopf(fmt, source)
  }

  # check that we have an output folder associated
  # with this job -- 'gsutil ls' will return with
  # non-zero status when attempting to query a
  # non-existent gs URL
  arguments <- (
    ShellArgumentsBuilder()
    ("ls")
    (source))

  status <- gexec(gsutil(), arguments())
  if (status) {
    fmt <- "no directory at path '%s'"
    stopf(fmt, source)
  }

  ensure_directory(destination)

  arguments <- (
    ShellArgumentsBuilder()
    ("cp")
    ("-R")
    (source)
    (destination))

  gexec(gsutil(), arguments())
}
