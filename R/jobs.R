
#' Google Cloud -- Submit a Training Job
#'
#' Upload a TensorFlow application to Google Cloud, and use that application
#' to train a model.
#'
#' @template roxlate-application
#' @template roxlate-config
#' @template roxlate-dots
#'
#' @export
train_cloudml <- function(application = getwd(),
                          config      = "cloudml",
                          ...)
{
  application <- scope_deployment(application)

  # resolve entrypoint
  dots <- list(...)
  entrypoint <- dots[["entrypoint"]] %||%
    config::get("train_entrypoint", config = config) %||%
    "train.R"

  # determine job name
  job_name <- dots[["job_name"]] %||%
    random_job_name(application, config)

  # determine job directory
  job_dir <- dots[["job_dir"]] %||%
    config::get("job_dir", config = config)

  # determine staging bucket
  staging_bucket <- dots[["staging_bucket"]] %||%
    config::get("staging_bucket", config = config)

  # determine region
  region <- dots[["region"]] %||%
    config::get("region", config = config) %||%
    "us-central1"

  # determine runtime version
  runtime_version <- dots[["runtime_version"]] %||%
    config::get("runtime_version", config = config) %||%
    "1.0"

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
  dots <- list(...)
  saveRDS(dots, file.path(application, "cloudml/config.rds"))

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
                (config))

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
    job_name = job_name,
    job_dir = job_dir
  )
}

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

job_collect <- function(job) {
  id <- job_name(job)

  # get the job status
  status <- job_status(job)

  # if we're already done, return early
  if (status$state == "SUCCEEDED")
    return(job_download(job))

  # otherwise, notify the user and begin polling
  fmt <- ">>> Job '%s' is currently running -- please wait..."
  printf(fmt, id)
  printf(">>> [state: %s]", status$state)

  # TODO: should we give up after a while? (user can always interrupt)
  repeat {

    # get the job status
    status <- job_status(job)

    if (status$state == "SUCCEEDED")
      return(job_download(job))

    # job isn't ready yet; sleep for a while and try again
    Sys.sleep(60)

  }

  stop("failed to receive job outputs")
}

job_download <- function(job, target = "jobs") {
  source <- job$job_dir
  target <- target %||% "jobs"

  ensure_directory(target)

  arguments <- (
    ShellArgumentsBuilder()
    ("cp")
    ("-R")
    (source)
    (target))

  gexec(gsutil(), arguments())
}
