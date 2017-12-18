
#' Train a model using Cloud ML
#'
#' Upload a TensorFlow application to Google Cloud, and use that application to
#' train a model.
#'
#' @inheritParams tfruns::training_run
#' @inheritParams gcloud_config
#'
#' @param file File to be used as entrypoint for training.
#'
#' @param scale_tier Machine type for training. "basic" provides a single
#'   worker instance suitable for learning how to use Cloud ML Engine,
#'   and for experimenting with new models using small datasets; "basic-gpu"
#'   provides a single worker instance with a GPU. "basic-tpu" provides a
#'   single worker instance with a TPU.
#'
#' @param cloudml A list, \code{YAML} or \code{JSON} configuration file as described
#'   \url{https://cloud.google.com/ml-engine/reference/rest/v1/projects.jobs}.
#'
#' @param collect Collect job when training is completed (blocks waiting
#'   for the job to complete).
#'
#' @seealso [job_status()], [job_collect()], [job_cancel()]
#'
#' @export
cloudml_train <- function(file = "train.R",
                          scale_tier = c("basic", "basic-gpu", "basic-tpu"),
                          flags = NULL,
                          cloudml = NULL,
                          gcloud = NULL,
                          collect = "ask")
{
  message("Submitting training job to CloudML...")

  # set application and entrypoint
  application <- getwd()
  entrypoint <- file

  # prepare application for deployment
  id <- unique_job_name("cloudml")
  deployment <- scope_deployment(
    id = id,
    application = application,
    context = "cloudml",
    overlay = flags,
    entrypoint = entrypoint,
    cloudml = cloudml,
    gcloud = gcloud
  )

  # read configuration
  gcloud <- gcloud_config()
  cloudml <- cloudml_config()
  cloudml_file <- deployment$cloudml_file

  # create default storage bucket for project if not specified
  storage <- getOption("cloudml.storage")
  if (is.null(storage)) {
    project <- gcloud[["project"]]
    if (!gcloud_project_has_bucket(project)) {
      gcloud_project_create_bucket(project)
    }
    storage <- file.path(gcloud_project_bucket(project), "r-cloudml")
  }

  # region is required
  default_region <- gcloud_default_region()
  gcloud$region <- if (nchar(default_region) == 0) "us-east1" else default_region

  # pass parameters to the job
  job_yml <- file.path(deployment$directory, "job.yml")
  yaml::write_yaml(list(
    storage = storage
  ), job_yml)

  # move to deployment parent directory and spray __init__.py
  directory <- deployment$directory
  scope_setup_py(directory)
  setwd(dirname(directory))

  cloudml_version <- cloudml$trainingOutput$runtimeVersion %||% "1.2"
  if (utils::compareVersion(cloudml_version, "1.2") < 0)
    stop("CloudML version ", cloudml_version, " is unsupported, use 1.2 or newer.")

  # generate deployment script
  arguments <- (MLArgumentsBuilder(gcloud)
                ("jobs")
                ("submit")
                ("training")
                (id)
                ("--job-dir=%s", file.path(storage, "staging"))
                ("--package-path=%s", basename(directory))
                ("--module-name=%s.cloudml.deploy", basename(directory))
                ("--runtime-version=%s", cloudml_version)
                ("--region=%s", gcloud[["region"]])
                ("--scale-tier=%s", match.arg(scale_tier))
                ("--config=%s/%s", "cloudml-model", cloudml_file)
                ("--")
                ("Rscript"))

  # submit job through command line interface
  gcloud_exec(args = arguments())

  # call 'describe' to discover additional information related to
  # the job, and generate a 'job' object from that
  #
  # print stderr output from a 'describe' call (this gives the
  # user URLs that can be navigated to for more information)
  arguments <- (MLArgumentsBuilder(gcloud)
                ("jobs")
                ("describe")
                (id))

  output <- gcloud_exec(args = arguments())
  stdout <- output$stdout
  stderr <- output$stderr

  # inform user of successful job submission
  template <- c(
    "Job '%1$s' successfully submitted.",
    "%2$s",
    "Check job status with:     job_status(\"%1$s\")",
    "",
    "Collect job output with:   job_collect(\"%1$s\")",
    "",
    "After collect, view with:  view_run(\"runs/%1$s\")",
    ""
  )
  rendered <- sprintf(paste(template, collapse = "\n"), id, stderr)
  message(rendered)

  # create job object
  description <- yaml::yaml.load(stdout)
  job <- cloudml_job("train", id, description)
  register_job(job)

  # resolve collect
  if (identical(collect, "ask")) {
    if (interactive()) {
      if (have_rstudio_terminal())
        response <- readline("Monitor and collect job in RStudio Terminal? [Y/n]: ")
      else
        response <- readline("Wait and collect job when completed? [Y/n]: ")
      collect <- !nzchar(response) || (tolower(response) == 'y')
    } else {
      collect <- FALSE
    }
  }

  # perform collect if required
  destination <- file.path(application, "runs")
  if (collect) {
    if (have_rstudio_terminal()) {
      job_collect_async(
        job,
        gcloud,
        destination = destination,
        view = identical(rstudioapi::versionInfo()$mode, "desktop")
      )
    } else {
      job_collect(
        job,
        destination = destination,
        view = interactive()
      )
    }
  }

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
job_cancel <- function(job = "latest", gcloud = NULL) {
  job <- as.cloudml_job(job, gcloud)

  arguments <- (MLArgumentsBuilder(gcloud)
                ("jobs")
                ("cancel")
                (job))

  gcloud_exec(args = arguments())
}

#' List all jobs
#'
#' List existing Google Cloud ML jobs.
#'
#' @inheritParams gcloud_config
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
                     uri       = FALSE,
                     gcloud    = NULL)
{
  arguments <- (
    MLArgumentsBuilder(gcloud)
    ("jobs")
    ("list")
    ("--filter=%s", filter)
    ("--limit=%i", as.integer(limit))
    ("--page-size=%i", as.integer(page_size))
    ("--sort-by=%s", sort_by)
    (if (uri) "--uri"))

  output <- gcloud_exec(args = arguments())

  if (!uri) {
    output_tmp <- tempfile()
    writeLines(output$stdout, output_tmp)
    jobs <- utils::read.table(output_tmp, header = TRUE, stringsAsFactors = FALSE)
    jobs$CREATED <- as.POSIXct(jobs$CREATED, format = "%Y-%m-%dT%H:%M:%S", tz = "GMT")
    output <- jobs
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
job_stream_logs <- function(job = "latest",
                            polling_interval = getOption("cloudml.stream_logs.polling", 5),
                            task_name = NULL,
                            allow_multiline_logs = FALSE,
                            gcloud = NULL)
{
  job <- as.cloudml_job(job, gcloud)

  arguments <- (
    MLArgumentsBuilder(gcloud)
    ("jobs")
    ("stream-logs")
    (job$id)
    ("--polling-interval=%i", as.integer(polling_interval))
    ("--task-name=%s", task_name))

  if (allow_multiline_logs)
    arguments("--allow-multiline-logs")

  gcloud_exec(args = arguments(), echo = TRUE)
  invisible(NULL)
}

#' Current status of a job
#'
#' Get the status of a job, as an \R list.
#'
#' @inheritParams gcloud_config
#'
#' @param job Job name or job object. Pass "latest" to indicate the
#'   most recently submitted job.
#'
#' @param gcloud A list or \code{YAML} file with optional 'account' or 'project'
#'   fields used to configure the GCloud environemnt.
#'
#' @family job management
#'
#' @export
job_status <- function(job = "latest",
                       gcloud = NULL) {
  job <- as.cloudml_job(job, gcloud)

  arguments <- (MLArgumentsBuilder(gcloud)
                ("jobs")
                ("describe")
                (job))

  # request job description from gcloud
  output <- gcloud_exec(args = arguments())

  # parse as YAML and return
  status <- yaml::yaml.load(paste(output$stdout, collapse = "\n"))

  class(status) <- "cloudml_job_status"
  attr(status, "messages") <- output$stderr
  status
}

#' @export
print.cloudml_job_status <- function(x, ...) {

  # strip generated attributes from trainingInput
  x$trainingInput$args <- NULL
  x$trainingInput$packageUris <- NULL
  x$trainingInput$pythonModule <- NULL

  str(x, give.attr = FALSE, no.list = TRUE)
  trails_data <- job_trials(x)
  if (!is.null(trails_data)) {
    cat("\n")
    cat("Hyperparameter Trials:\n")
    print(trails_data)
  }

  cat(attr(x, "messages"), "\n")
}

#' Current trials of a job
#'
#' Get the hyperparameter trials for job, as an \R data frame
#'
#' @inheritParams gcloud_exec
#' @inheritParams job_status
#
#' @param x Job name or job object.
#'
#' @family job management
#'
#' @export
job_trials <- function(x, gcloud = NULL) {
  UseMethod("job_trials")
}

job_trials_from_status <- function(status) {
  if (is.null(status$trainingOutput) || is.null(status$trainingOutput$trials))
    return(NULL)

  do.call("rbind", lapply(status$trainingOutput$trials, as.data.frame))
}

#' @export
job_trials.character <- function(x, gcloud = NULL) {
  status <- job_status(x, gcloud)
  job_trials_from_status(status)
}

#' @export
job_trials.cloudml_job <- function(x, gcloud = NULL) {
  job_trials_from_status(x$description)
}

#' @export
job_trials.cloudml_job_status <- function(x, gcloud = NULL) {
  job_trials_from_status(x)
}

job_validate_trials <- function(trials) {
  if (!is.null(trials)) {
    if (!is.numeric(trials) && !trials %in% c("best", "all"))
      stop("The 'trials' parameter must be numeric, 'best' or 'all'.")
  }
}

#' Collect job output
#'
#' Collect the job outputs (e.g. fitted model) from a job. If the job has not
#' yet finished running, `job_collect()` will block and wait until the job has
#' finished.
#'
#' @inheritParams job_status
#'
#' @param trials Under hyperparameter tuning, specifies which trials to
#'   download. Use \code{"best"} to download best trial, \code{"all"} to
#'   download all, or a vector of trials \code{c(1,2)} or \code{1}.
#'
#' @param destination The destination directory in which model outputs should
#'   be downloaded. Defaults to `runs`.
#'
#' @param timeout Give up collecting job after the specified minutes.
#'
#' @param view View the job results after collecting it. You can also pass
#'   "save" to save a copy of the run report at `tfruns.d/view.html`
#'
#'
#' @family job management
#'
#' @export
job_collect <- function(job = "latest",
                        trials = "best",
                        destination = "runs",
                        timeout = NULL,
                        view = interactive(),
                        gcloud = NULL) {

  job <- as.cloudml_job(job, gcloud)
  id <- job$id
  job_validate_trials(trials)

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
  if (status$state %in% c("SUCCEEDED", "FAILED")) {
    return(job_download_multiple(
      job,
      trial = trials,
      destination = destination,
      view = view,
      gcloud = gcloud)
    )
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
    if (status$state %in% c("SUCCEEDED", "FAILED")) {
      printf("\n")
      return(job_download_multiple(job,
                                   trial = trials,
                                   destination = destination,
                                   view = view,
                                   gcloud = gcloud))
    }

    # job isn't ready yet; sleep for a while and try again
    Sys.sleep(30)

    if (!is.null(timeout) && time - start_time > timeout * 60)
      stop("Giving up after ", timeout, " minutes with job in status ", status$state)
  }

  stop("failed to receive job outputs")
}

# Collect Job Output Asynchronously
job_collect_async <- function(
  job,
  gcloud = NULL,
  destination = "runs",
  polling_interval = getOption("cloudml.stream_logs.polling", 5),
  view = interactive()
) {

  if (!have_rstudio_terminal())
    stop("job_collect_async requires a version of RStudio with terminals (>= v1.1)")

  output_dir <- job_output_dir(job, gcloud)
  job <- as.cloudml_job(job)
  id <- job$id

  log_arguments <- (MLArgumentsBuilder(gcloud)
                   ("jobs")
                   ("stream-logs")
                   (id)
                   ("--polling-interval=%i", as.integer(polling_interval)))

  if (.Platform$OS.type == "windows") {
    os_collapse <-  " & "
    os_return   <- "\r\n"
  } else {
    os_collapse <- " ; "
    os_return   <- "\n"
  }

  terminal_steps <- c(
    paste(gcloud_binary(), paste(log_arguments(), collapse = " "))
  )

  destination <- normalizePath(destination, mustWork = FALSE)
  if (!job_is_tuning(job)) {
    terminal_steps <- c(terminal_steps, collect_job_step(destination, job$id))
    if (view)
      terminal_steps <- c(terminal_steps, view_job_step(destination, job$id))
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

  gcloud_terminal(terminal_command, clear = TRUE)
}

job_download <- function(job,
                         trial = "best",
                         destination = "runs",
                         view = interactive(),
                         gcloud) {

  status <- job_status(job, gcloud)

  # retrieve the gs-compatible source URL to copy from and the final
  # run directory which might be modified to include the trial number
  trial_paths <- job_status_trial_dir(status, destination, trial, job)
  source <- trial_paths$source
  destination <- trial_paths$destination

  if (!is_gs_uri(source)) {
    fmt <- "job directory '%s' is not a Google Storage URI"
    stopf(fmt, source)
  }

  message(sprintf("Downloading job from %s...", source))

  # check that we have an output folder associated
  # with this job -- 'gsutil ls' will return with
  # non-zero status when attempting to query a
  # non-existent gs URL
  result <- gsutil_exec("ls", source)

  if (result$status != 0) {
    fmt <- "no directory at path '%s'"
    stopf(fmt, source)
  }

  ensure_directory(destination)
  gs_copy(source, destination, TRUE, echo = TRUE)

  # write cloudml properties to run_dir
  run_dir <- destination
  as_date <- function(x) {
    tryCatch(as.double(as.POSIXct(x,
                                  tz = "GMT",
                                  format = "%Y-%m-%dT%H:%M:%SZ")),
             error = function(e) NULL)
  }
  properties <- list()
  properties$cloudml_job <- status$jobId
  properties$cloudml_state <- status$state
  properties$cloudml_error <- status$errorMessage
  properties$cloudml_created <- as_date(status$createTime)
  properties$cloudml_start <- as_date(status$startTime)
  properties$cloudml_end <- as_date(status$endTime)
  properties$cloudml_ml_units <- status$trainingOutput$consumedMLUnits
  properties$cloudml_scale_tier <- status$trainingInput$scaleTier
  messages <- trimws(strsplit(attr(status, "messages"), "\n")[[1]])
  messages <- messages[grepl("^https://.*$", messages)]
  for (message in messages) {
    if (startsWith(message, "https://console.cloud.google.com/ml/jobs/"))
      properties$cloudml_console_url <- message
    else if (startsWith(message, "https://console.cloud.google.com/logs"))
      properties$cloudml_log_url <- message
  }
  tfruns::write_run_metadata("properties", properties, run_dir)

  if (isTRUE(view) && trial != "all")
    tfruns::view_run(run_dir)
  else if (view == "save")
    tfruns::save_run_view(run_dir, file.path(run_dir, "tfruns.d", "view.html"))

  invisible(status)
}

job_list_trials <- function(job) {
  as.numeric(sapply(job$description$trainingOutput$trials, function(e) e$trialId))
}

job_download_multiple <- function(job, trial, destination, view, gcloud) {
  if (length(trial) <= 1 && trial != "all")
    job_download(job, trial, destination, view, gcloud)
  else {
    if (identical(trial, "all")) trial <- job_list_trials(job)
    lapply(trial, function(t) {
      job_download(job, t, destination, FALSE, gcloud)
    })
  }
}

job_output_dir <- function(job, gcloud) {

  # determine storage from job
  job <- as.cloudml_job(job, gcloud)
  storage <- dirname(job$description$trainingInput$jobDir)

  output_path <- file.path(storage, "runs", job$id)

  if (job_is_tuning(job) && !is.null(job$trainingOutput$finalMetric)) {
    output_path <- file.path(output_path, job$trainingOutput$finalMetric$trainingStep)
  }

  output_path
}

job_status_trial_dir <- function(status, destination, trial, job) {

  # determine storage from job
  storage <- dirname(status$trainingInput$jobDir)

  output_path <- list(
    source = file.path(storage, "runs", status$jobId, "*", fsep = "/"),
    destination = file.path(destination, status$jobId)
  )

  if (!is.null(trial) && job_is_tuning(job)) {
    trial_digits_format <- paste0("%0", nchar(max(job_list_trials(job))), "d")
    trial_parent <- file.path(storage, "runs", status$jobId)
    if (trial == "best") {
      if (job_status_is_tuning(status) && !is.null(status$trainingInput$hyperparameters$goal)) {
        decreasing <- if (status$trainingInput$hyperparameters$goal == "MINIMIZE") FALSE else TRUE
        ordered <- order(sapply(status$trainingOutput$trials, function(e) e$finalMetric$objectiveValue), decreasing = TRUE)
        if (length(ordered) > 0) {
          best_trial <- as.numeric(status$trainingOutput$trials[[ordered[[1]]]]$trialId)
          output_path <- list(
            source = file.path(trial_parent, best_trial, "*"),
            destination = file.path(
              destination,
              paste(
                status$jobId,
                sprintf(trial_digits_format, best_trial),
                sep = "-"
              )
            )
          )
        }
      }
    }
    else if (is.numeric(trial)) {
      output_path <- list(
        source = file.path(trial_parent, trial, "*"),
        destination = file.path(
          destination,
          paste(
            status$jobId,
            sprintf(trial_digits_format, trial),
            sep = "-"
          )
        )
      )
    }
  }

  output_path
}

job_is_tuning <- function(job) {
  !is.null(job$description$trainingInput$hyperparameters)
}

job_status_is_tuning <- function(status) {
  identical(status$trainingOutput$isHyperparameterTuningJob, TRUE)
}

collect_job_step <- function(destination, jobId) {
  r_job_step(paste0(
    "cloudml::job_collect('", jobId, "', destination = '", destination, "', view = 'save')"
  ))
}



view_job_step <- function(destination, jobId) {
  r_job_step(paste0(
    "utils::browseURL('",
    file.path(destination, jobId, "tfruns.d", "view.html"),
    "')"
  ))
}

r_job_step <- function(command) {
  paste(
    paste0("\"", file.path(R.home("bin"), "Rscript"), "\""),
    "-e",
    paste0("\"", command ,"\"")
  )
}
