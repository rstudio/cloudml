
#' Google Cloud -- Submit a Training Job
#'
#' Upload a TensorFlow application to Google Cloud, and use that application to
#' train a model.
#'
#' @template roxlate-application
#' @template roxlate-config
#' @template roxlate-dots
#'
#' @inheritParams train_local
#'
#' @family jobs
#'
#' @export
train_cloudml <- function(application = getwd(),
                          config      = "cloudml",
                          job_dir     = NULL,
                          ...)
{
  application <- scope_deployment(application)
  config_name <- config
  config <- cloudml::config(config = config)

  # resolve extra config
  extra_config <- list(...)
  if (!is.null(job_dir))
    extra_config$job_dir <- job_dir

  # resolve entrypoint
  entrypoint <- extra_config[["entrypoint"]] %||%
    config$train_entrypoint %||% "train.R"

  # determine job name
  job_name <- extra_config[["job_name"]] %||%
    random_job_name(application, config)

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
  saveRDS(extra_config, file.path(application, ".cloudml_config.rds"))

  # generate deployment script
  arguments <- (ShellArgumentsBuilder()
                ("beta")
                ("ml")
                ("jobs")
                ("submit")
                ("training")
                (job_name)
                ("--package-path=%s", basename(application))
                ("--module-name=%s.cloudml.deploy", basename(application))
                (if (!is.null(job_dir)) c("--job-dir=%s", job_dir))
                (if (!is.null(staging_bucket)) c("--staging-bucket=%s", staging_bucket))
                ("--region=%s", region)
                ("--async")
                ("--runtime-version=%s", runtime_version)
                ("--")
                (entrypoint)
                (config_name)
                ("--environment=gcloud"))

  # submit job through command line interface
  output <- gexec(gcloud(), arguments(), stdout = TRUE, stderr = TRUE)

  # extract job id from output
  index <- grep("^jobId:", output)
  job_name <- substring(output[index], 8)

  # emit first line of output
  cat(output[1], sep = "\n")

  # return job object
  cloudml_job(
    "train",
    app_dir  = application,
    job_name = job_name,
    job_dir  = job_dir
  )
}

#' Google Cloud -- Cancel a Job
#'
#' Cancel a job.
#'
#' @template roxlate-job
#' @family jobs
#' @export
job_cancel <- function(job) {
  id <- job_name(job)

  arguments <- (
    ShellArgumentsBuilder()
    ("beta")
    ("ml")
    ("jobs")
    ("cancel")
    (id))

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
  id <- job_name(job)

  arguments <- (
    ShellArgumentsBuilder()
    ("beta")
    ("ml")
    ("jobs")
    ("describe")
    (id))

  gexec(gcloud(), arguments())
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
    ShellArgumentsBuilder()
    ("beta")
    ("ml")
    ("jobs")
    ("list")
    (if (!is.null(filter))    c("--filter=%s", filter))
    (if (!is.null(limit))     c("--limit=%s", limit))
    (if (!is.null(page_size)) c("--page-size=%s", page_size))
    (if (!is.null(sort_by))   c("--sort-by=%s", sort_by))
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
  id <- job_name(job)

  arguments <- (
    ShellArgumentsBuilder()
    ("beta")
    ("ml")
    ("jobs")
    ("stream-logs")
    (id)
    (sprintf("--polling-interval=%i", as.integer(polling_interval)))
    (if (!is.null(task_name)) sprintf("--task-name=%s", task_name))
    (if (allow_multiline_logs) "--allow-multiline-logs"))

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
  id <- job_name(job)

  arguments <- (
    ShellArgumentsBuilder()
    ("beta")
    ("ml")
    ("jobs")
    ("describe")
    (id))

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
job_collect <- function(job, destination = "jobs/cloudml")
{
  # TODO: we need to handle job failures here
  id <- job_name(job)

  # get the job status
  status <- job_status(job)

  # if we're already done, return early
  if (status$state == "SUCCEEDED")
    return(job_download(job, destination))

  # otherwise, notify the user and begin polling
  fmt <- ">>> Job '%s' is currently running -- please wait..."
  printf(fmt, id)
  printf(">>> [state: %s]", status$state)

  # TODO: should we give up after a while? (user can always interrupt)
  repeat {

    # get the job status
    status <- job_status(job)

    if (status$state == "SUCCEEDED")
      return(job_download(job, destination))

    # job isn't ready yet; sleep for a while and try again
    Sys.sleep(60)

  }

  stop("failed to receive job outputs")
}

job_download <- function(job, destination = "jobs/cloudml")
{
  source <- job$job_dir

  ensure_directory(destination)

  arguments <- (
    ShellArgumentsBuilder()
    ("cp")
    ("-R")
    (source)
    (destination))

  gexec(gsutil(), arguments())
}
