
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
#' @param entrypoint
#'   File to be used as entrypoint for training.
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

  # create default storage bucket for project if not specified
  if (is.null(cloudml[["storage"]])) {
    project <- gcloud[["project"]]
    project_bucket <- gcloud_project_bucket(project)
    if (!gcloud_project_has_bucket(project)) {
      gcloud_project_create_bucket(project)
    }
    cloudml$storage <- gcloud_project_bucket(project)
  }

  # move to deployment parent directory and spray __init__.py
  directory <- deployment$directory
  scope_setup_py(directory)
  setwd(dirname(directory))

  cloudml_version <- cloudml[["runtime-version"]] %||% "1.2"
  if (compareVersion(cloudml_version, "1.2") < 0)
    stop("CloudML version ", cloudml_version, " is unsupported, use 1.2 or newer.")

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
                ("--runtime-version=%s", cloudml_version)
                ("--region=%s", gcloud[["region"]])
                ("--config=%s/%s", basename(application), overlay$hypertune)
                ("--")
                ("Rscript"))

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

  if (interactive())
    job_collect_async(job, cloudml)

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
  status <- yaml::yaml.load(paste(output$stdout, collapse = "\n"))

  invisible(status)
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
#'   be downloaded. Defaults to `runs`.
#'
#' @param timeout
#'   Give up collecting job after the specified minutes.
#'
#' @family job management
#'
#' @export
job_collect <- function(job, destination = "runs", timeout = NULL) {
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

  start_time <- Sys.time()

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

    if (!is.null(timeout) && time - start_time > timeout * 60)
      stop("Giving up after ", timeout, " minutes with job in status ", status$state)
  }

  stop("failed to receive job outputs")
}

#' Collect Job Output Asynchronously
#'
#' Collect the job outputs (e.g. fitted model) from a job asynchronously
#' using the RStudio terminal, if available.
#'
#' @inheritParams job_status
#'
#' @param gcloud
#'   Optional gcloud configuration.
#'
#' @param destination
#'   The destination directory in which model outputs should
#'   be downloaded. Defaults to `runs`.
#'
#' @param polling_interval
#'   Number of seconds to wait between efforts to fetch the
#'   latest log messages.
#'
#' @family job management
job_collect_async <- function(
  job,
  gcloud = NULL,
  destination = "runs",
  polling_interval = getOption("cloudml.collect.polling", 10)
) {
  if (!rstudioapi::isAvailable()) return()

  output_dir <- job_output_dir(job, gcloud)
  job <- as.cloudml_job(job)
  id <- job$id

  log_arguments <- (MLArgumentsBuilder()
                   ("jobs")
                   ("stream-logs")
                   (id)
                   ("--polling-interval=%i", as.integer(polling_interval)))

  download_arguments <- paste(
    gsutil_path(),
    "cp",
    "-r",
    shQuote(output_dir),
    shQuote(destination)
  )

  if (.Platform$OS.type == "windows") {
    os_collapse <-  " & "
    os_return   <- "\r\n"
  } else {
    os_collapse <- " ; "
    os_return   <- "\n"
  }

  terminal_steps <- c(
    paste(gcloud_path(), paste(log_arguments(), collapse = " "))
  )

  if (!job_is_tuning(job)) {
    terminal_steps <- c(
      terminal_steps,
      paste("mkdir -p", destination),
      paste(download_arguments, collapse = " "),
      paste("echo \"\""),
      paste("echo \"To view the results, run from R: tfruns::view_run()\"")
    )
  }
  else {
    terminal_steps <- c(
      terminal_steps,
      paste("echo \"\""),
      paste(
        "echo \"To collect this job, run from R: job_collect('",
        job$id,
        "')\"",
        sep = ""
      )
    )
  }

  terminal_command <- paste(
    terminal_steps,
    collapse = os_collapse
  )

  terminal <- rstudioapi::terminalCreate()
  rstudioapi::terminalSend(terminal, paste0(terminal_command, os_return))
}

job_download <- function(job, destination = "runs") {
  status <- job_status(job)

  trial_paths <- job_status_trial_dir(status, destination)
  source <- trial_paths$source
  destination <- trial_paths$destination

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

job_output_dir <- function(job, config = cloudml_config()) {
  output_path <- file.path(config$storage, "runs", job$id)

  if (job_is_tuning(job) && !is.null(job$trainingOutput$finalMetric)) {
    output_path <- file.path(output_path, job$trainingOutput$finalMetric$trainingStep)
  }

  output_path
}

job_status_trial_dir <- function(status, destination, config = cloudml_config()) {
  output_path <- list(
    source = file.path(config$storage, "runs", status$jobId),
    destination = destination
  )

  if (job_status_is_tuning(status) && !is.null(status$trainingInput$hyperparameters$goal)) {
    decreasing <- if (status$trainingInput$hyperparameters$goal == "MINIMIZE") FALSE else TRUE
    ordered <- order(sapply(status$trainingOutput$trials, function(e) e$finalMetric$objectiveValue), decreasing = TRUE)
    if (length(ordered) > 0) {

      output_path <- list(
        source = file.path(output_path$source, status$trainingOutput$trials[[ordered[[1]]]]$trialId, "*"),
        destination = file.path(destination, status$jobId)
      )
    }
  }

  output_path
}

job_is_tuning <- function(job) {
  !is.null(job$description$trainingInput$hyperparameters)
}

job_status_is_tuning <- function(status) {
  !identical(status$trainingOutput$isHyperparameterTuningJob, TRUE)
}
