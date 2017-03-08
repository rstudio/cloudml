#' Train a Model Locally
#'
#' Train a model locally, using the `gcloud` command line
#' utility. This can be used as a testing bed for TensorFlow
#' applications which you want to later run on Google Cloud,
#' submitted using [train_cloudml()].
#'
#' @template roxlate-application
#' @template roxlate-config
#' @template roxlate-dots
#'
#' @param job_dir Directory to write job into (defaults to the value
#'   of `job_dir` in the `config.yml` file).
#'
#' @export
train_local <- function(application = getwd(),
                        config      = "default",
                        job_dir     = NULL,
                        ...)
{
  Sys.setenv(CLOUDML_EXECUTION_ENVIRONMENT = "local")
  on.exit(Sys.unsetenv("CLOUDML_EXECUTION_ENVIRONMENT"), add = TRUE)

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

  # move to application's parent directory
  owd <- setwd(dirname(application))
  on.exit(setwd(owd), add = TRUE)

  # serialize '...' as extra arguments to be merged
  # with the config file
  saveRDS(extra_config, file.path(application, "cloudml/config.rds"))

  # generate arguments for gcloud call
  arguments <- (MLArgumentsBuilder()
                ("local")
                ("train")
                ("--package-path=%s", basename(application))
                ("--module-name=%s.cloudml.deploy", basename(application))
                ("--")
                ("--cloudml-entrypoint=%s", entrypoint)
                ("--cloudml-config=%s", config_name)
                ("--cloudml-environment=local"))

  gexec(gcloud(), arguments())
}
