
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
#'   settings to your TensorFlow application.
#'
#' @seealso [job_describe()], [job_collect()], [job_cancel()]
#'
#' @export
cloudml_train <- function(application = getwd(),
                          config      = "cloudml",
                          entrypoint  = "train.R",
                          ...)
{
  # prepare application for deployment
  id <- unique_job_name(application, config)
  overlay <- list(...)
  deployment <- scope_deployment(
    id = id,
    application = application,
    context = "cloudml",
    config = config,
    overlay = overlay,
    entrypoint = entrypoint
  )

  # read configuration
  gcloud <- gcloud_config()
  cloudml <- cloudml_config()

  # move to deployment parent directory and spray __init__.py
  directory <- deployment$directory
  scope_setup_py(directory)
  setwd(dirname(directory))

  # generate deployment script
  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("submit")
                ("training")
                (id)
                ("--job-dir=%s", file.path(cloudml[["storage"]], "staging"))
                ("--package-path=%s", basename(directory))
                ("--module-name=%s.cloudml.deploy", basename(directory))
                ("--staging-bucket=%s", gcloud[["staging-bucket"]])
                ("--runtime-version=%s", gcloud[["runtime-version"]])
                ("--region=%s", gcloud[["region"]])
                ("--")
                ("Rscript"))

                # TODO: re-enable these
                # ("--job-dir=%s", overlay$job_dir)
                # ("--staging-bucket=%s", overlay$staging_bucket)
                # ("--region=%s", overlay$region)
                # ("--runtime-version=%s", overlay$runtime_version)
                # ("--config=%s/%s", basename(application), overlay$hypertune)

  # submit job through command line interface
  gcloud_exec(args = arguments())

  # inform user of successful job submission
  template <- c(
    "Job '%1$s' successfully submitted.",
    "",
    "Check status and collect output with:",
    "- job_status(\"%1$s\")",
    "- job_collect(\"%1$s\")"
  )

  rendered <- sprintf(paste(template, collapse = "\n"), id)
  message(rendered)

  # call 'describe' to discover additional information related to
  # the job, and generate a 'job' object from that
  #
  # print stderr output from a 'describe' call (this gives the
  # user URLs that can be navigated to for more information)
  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("describe")
                (id))

  output <- gcloud_exec(args = arguments())
  stdout <- output$stdout
  stderr <- output$stderr

  # write stderr to the console
  message(stderr)

  # create job object
  description <- yaml::yaml.load(stdout)
  job <- cloudml_job("train", id, description)
  register_job(job)

  invisible(job)
}

#' Cancel a job
#'
#' Cancel a job.
#'
#' @inheritParams job_status
#'
#' @family job management
#'
#' @export
job_cancel <- function(job) {
  job <- as.cloudml_job(job)

  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("cancel")
                (job))

  gcloud_exec(args = arguments())
}

#' Describe a job
#'
#' @inheritParams job_status
#'
#' @family job management
#'
#' @export
job_describe <- function(job) {
  job <- as.cloudml_job(job)

  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("describe")
                (job))

  output <- gcloud_exec(args = arguments())

  # return as R list
  yaml::yaml.load(paste(output$stdout, collapse = "\n"))
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

  output <- gcloud_exec(args = arguments())

  if (!uri) {
    pasted <- paste(output$stdout, collapse = "\n")
    output <- readr::read_table2(pasted)
  }

  output
}


#' Show job log stream
#'
#' Show logs from a running Cloud ML Engine job.
#'
#' @inheritParams job_status
#'
#' @param polling_interval
#'   Number of seconds to wait between efforts to fetch the
#'   latest log messages.
#'
#' @param task_name
#'   If set, display only the logs for this particular task.
#'
#' @param allow_multiline_logs
#'   Output multiline log messages as single records.
#'
#' @family job management
#'
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

  output <- gcloud_exec(args = arguments())
  print(output$stdout)
}

#' Current status of a job
#'
#' Get the status of a job, as an \R list.
#'
#' @param job Job name or job object.
#'
#' @family job management
#'
#' @export
job_status <- function(job) {
  job <- as.cloudml_job(job)

  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("describe")
                (job))

  # request job description from gcloud
  output <- gcloud_exec(args = arguments())

  # parse as YAML and return
  yaml::yaml.load(paste(output$stdout, collapse = "\n"))
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
#' @family job management
#'
#' @export
job_collect <- function(job, destination = "jobs/cloudml") {
  job <- as.cloudml_job(job)
  id <- job$id

  # helper function for writing job status to console
  write_status <- function(status, time) {

    # generate message
    fmt <- ">>> [state: %s; last updated %s]"
    msg <- sprintf(fmt, status$state, time)

    whitespace <- ""
    width <- getOption("width")
    if (nchar(msg) < width)
      whitespace <- paste(rep("", width - nchar(msg)), collapse = " ")

    # generate and write console text (overwrite old output)
    output <- paste0("\r", msg, whitespace)
    cat(output, sep = "")

  }

  # get the job status
  status <- job_status(job)
  time <- Sys.time()

  # if we're already done, attempt download of outputs
  if (status$state == "SUCCEEDED")
    return(job_download(job, destination))

  # if the job has failed, report error
  if (status$state == "FAILED") {
    fmt <- "job '%s' failed [state: %s]"
    stopf(fmt, id, status$state)
  }

  # otherwise, notify the user and begin polling
  fmt <- ">>> Job '%s' is currently running -- please wait...\n"
  printf(fmt, id)

  write_status(status, time)

  # TODO: should we give up after a while? (user can always interrupt)
  repeat {

    # get the job status
    status <- job_status(job)
    time <- Sys.time()
    write_status(status, time)

    # download outputs on success
    if (status$state == "SUCCEEDED") {
      printf("\n")
      return(job_download(job, destination))
    }

    # if the job has failed, report error
    if (status$state == "FAILED") {
      printf("\n")
      fmt <- "job '%s' failed [state: %s]"
      stopf(fmt, id, status$state)
    }

    # job isn't ready yet; sleep for a while and try again
    Sys.sleep(30)

  }

  stop("failed to receive job outputs")
}

job_download <- function(job, destination = "jobs/cloudml") {
  source <- job_output_dir(job)

  if (!is_gs_uri(source)) {
    fmt <- "job directory '%s' is not a Google Storage URI"
    stopf(fmt, source)
  }

  # check that we have an output folder associated
  # with this job -- 'gsutil ls' will return with
  # non-zero status when attempting to query a
  # non-existent gs URL
  result <- gsutil_exec("ls", source)

  if (result$status) {
    fmt <- "no directory at path '%s'"
    stopf(fmt, source)
  }

  ensure_directory(destination)
  gsutil_copy(source, destination, TRUE)
}

job_output_dir <- function(job) {
  config <- cloudml_config()
  file.path(config$storage, "runs", job$id)
}
