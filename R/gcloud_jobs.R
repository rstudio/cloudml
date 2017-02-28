#' Google Cloud -- Submit a Training Job
#'
#' Upload a TensorFlow application to Google Cloud, and use that application
#' to train a model.
#'
#' @template roxlate-application
#' @template roxlate-entrypoint
#' @template roxlate-config

#' @param job.name
#'   The name to assign to the submitted job.
#'
#' @param job.dir
#'   A Google Cloud Storage path in which to
#'   store training outputs and other data needed for
#'   training.
#'
#'   If packages must be uploaded and `--staging-bucket` is
#'   not provided, this path will be used instead.
#'
#' @param staging.bucket
#'   Bucket in which to stage training archives.
#'
#'   Required only if a file upload is necessary (that is,
#'   other flags include local paths) and no other flags
#'   implicitly specify an upload path.
#'
#' @param runtime.version
#'   The Google Cloud ML runtime version for this job.
#'
#' @param region
#'   The region of the machine learning training job to submit.
#'
#' @param async
#'   Run the job asynchronously? When `FALSE`, this call will
#'   block until the TensorFlow job has run to completion.
#'
#' @export
cloudml_jobs_submit_training <- function(application     = getwd(),
                                         entrypoint      = "train.R",
                                         config          = "gcloud",
                                         job.name        = NULL,
                                         job.dir         = NULL,
                                         staging.bucket  = NULL,
                                         runtime.version = "1.0",
                                         region          = "us-central1",
                                         async           = TRUE)
{
  # initialize parameters that depend on config.yml
  config_path <- file.path(application, "config.yml")
  job.name <- job.name %||% cloudml_random_job_name(application, config)
  job.dir <- job.dir %||% config::get("job_dir", config, config_path)
  staging.bucket <- staging.bucket %||% config::get("staging_bucket", config, config_path)

  # ensure application initialized
  initialize_application(application)
  owd <- setwd(dirname(application))
  on.exit(setwd(owd), add = TRUE)

  # generate setup script
  if (!file.exists("setup.py")) {
    file.copy(
      system.file("cloudml/setup.py", package = "cloudml"),
      "setup.py",
      overwrite = TRUE
    )
    setup.py <- normalizePath("setup.py")
    on.exit(unlink(setup.py), add = TRUE)
  }

  # generate deployment script
  arguments <- (ShellArgumentsBuilder()
                ("beta")
                ("ml")
                ("jobs")
                ("submit")
                ("training")
                (job.name)
                ("--package-path=%s", basename(application))
                ("--module-name=%s.deploy", basename(application))
                ("--job-dir=%s", job.dir)
                ("--staging-bucket=%s", staging.bucket)
                ("--region=%s", region)
                (if (async) "--async")
                ("--runtime-version=%s", runtime.version)
                ("--")
                (entrypoint)
                (config))

  # TODO: serialize 'dynamic.config' to a special place and ensure it's
  # loaded when running associated entrypoint

  # submit job through command line
  system2(gcloud(), arguments())
}

cloudml_jobs_cancel <- "TODO"
cloudml_jobs_describe <- "TODO"
cloudml_jobs_list <- "TODO"
cloudml_jobs_logs <- "TODO"
