
#' Google Cloud -- Submit a Training Job
#'
#' Upload a TensorFlow application to Google Cloud, and use that application to
#' train a model.
#'
#' @template roxlate-application
#' @template roxlate-config
#' @template roxlate-dots
#'
#' @inheritParams local_train
#'
#' @family jobs
#'
#' @export
cloudml_train <- function(application = getwd(),
                          config      = "cloudml",
                          job_dir     = NULL,
                          ...)
{
  Sys.setenv(CLOUDML_EXECUTION_ENVIRONMENT = "gcloud")
  on.exit(Sys.unsetenv("CLOUDML_EXECUTION_ENVIRONMENT"), add = TRUE)

  application <- scope_deployment(application)
  config_name <- config
  config <- cloudml::config(config = config)

  # resolve extra config
  extra_config <- list(...)

  # resolve entrypoint
  entrypoint <- extra_config[["entrypoint"]] %||%
    config$train_entrypoint %||% "train.R"

  # determine job name
  job_name <- extra_config[["job_name"]] %||%
    unique_job_name(application, config_name)

  # determine job directory
  job_dir <- extra_config[["job_dir"]] %||% config$job_dir

  # determine staging bucket
  staging_bucket <- extra_config[["staging_bucket"]] %||% config$staging_bucket

  # determine region
  region <- extra_config[["region"]] %||%
    config$region  %||% "us-central1"

  # determine runtime version
  runtime_version <- extra_config[["runtime_version"]] %||%
    config$runtime_version %||%  "1.0"

  # ensure 'job_dir' is passed through extra config
  extra_config$job_dir <- job_dir

  # move to application's parent directory
  owd <- setwd(dirname(application))
  on.exit(setwd(owd), add = TRUE)

  # generate setup script (used to build the application as a Python
  # package remotely)
  if (!file.exists("setup.py")) {
    file.copy(
      system.file("cloudml/setup.py", package = "cloudml"),
      "setup.py",
      overwrite = TRUE
    )
    setup.py <- normalizePath("setup.py")
    on.exit(unlink(setup.py), add = TRUE)
  }

  # serialize '...' as extra arguments to be merged
  # with the config file
  ensure_directory(file.path(application, "cloudml"))
  saveRDS(extra_config, file.path(application, "cloudml/config.rds"))

  # generate deployment script
  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("submit")
                ("training")
                (job_name)
                ("--package-path=%s", basename(application))
                ("--module-name=%s.cloudml.deploy", basename(application))
                ("--job-dir=%s", job_dir)
                ("--staging-bucket=%s", staging_bucket)
                ("--region=%s", region)
                ("--async")
                ("--runtime-version=%s", runtime_version)
                ("--")
                ("--cloudml-entrypoint=%s", entrypoint)
                ("--cloudml-config=%s", config_name)
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
    "Job %1$s successfully submitted.",
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

#' Google Cloud -- Cancel a Job
#'
#' Cancel a job.
#'
#' @template roxlate-job
#' @family jobs
#' @export
job_cancel <- function(job) {
  job <- as.cloudml_job(job)

  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("cancel")
                (job_name(job)))

  gexec(gcloud(), arguments())
}

#' Google Cloud -- Describe a Job
#'
#' Describe a job.
#'
#' @template roxlate-job
#' @family jobs
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

#' Google Cloud -- List Jobs
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
#' @family jobs
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

#' Google Cloud -- Stream Logs from a Job
#'
#' Show logs from a running Cloud ML Engine job.
#'
#' @template roxlate-job
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
#' @family jobs
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

#' Google Cloud -- Job Status
#'
#' Get the status of a job, as an \R list.
#'
#' @template roxlate-job
#'
#' @family jobs
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

#' Collect Results from a Job
#'
#' Collect the job outputs (e.g. fitted model) from a job.
#' If the job has not yet finished running, `job_collect()`
#' will block and wait until the job has finished.
#'
#' @template roxlate-job
#'
#' @param destination
#'   The destination directory in which model outputs should
#'   be downloaded. Defaults to `jobs/cloudml`.
#'
#' @family jobs
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
