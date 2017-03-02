#' Generate a Job Directory
#'
#' Generate a job directory (as a relative path). Useful for
#' deployments when you want model artefacts to be confined to
#' a unique directory.
#'
#' @export
job_dir <- function(prefix = "jobs") {
  sprintf(
    "%s/%s_%i",
    prefix,
    format(Sys.time(), "%Y%m%d"),
    as.integer(Sys.time())
  )
}

#' Google Cloud -- Submit a Training Job
#'
#' Upload a TensorFlow application to Google Cloud, and use that application
#' to train a model.
#'
#' @param ... Additional configuration values for this training run
#'
#' @template roxlate-application
#' @template roxlate-config
#' @template roxlate-async
#' @template roxlate-dots
#'
#' @export
train_cloud <- function(application = getwd(),
                        config      = "gcloud",
                        async       = TRUE,
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
                (if (async) "--async")
                ("--runtime-version=%s", runtime_version)
                ("--")
                (entrypoint)
                (config))

  # submit job through command line interface
  # (handle command line output in async case)
  if (async) {
    output <- system2(
      gcloud(),
      arguments(),
      stdout = TRUE,
      stderr = TRUE
    )

    # extract job id from output
    index <- grep("^jobId:", output)
    id <- substring(output[index], 8)

    # emit first line of output
    cat(output[1], sep = "\n")

    # return job id
    return(id)
  }

  # non-async -- just run and block
  system2(gcloud(), arguments())

}

cloudml_jobs_cancel <- "TODO"
cloudml_jobs_describe <- "TODO"
cloudml_jobs_list <- "TODO"
cloudml_jobs_logs <- "TODO"
