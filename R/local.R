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
  saveRDS(extra_config, file.path(application, ".cloudml_config.rds"))

  # generate arguments for gcloud call
  arguments <- (ShellArgumentsBuilder()
                ("beta")
                ("ml")
                ("local")
                ("train")
                ("--package-path=%s", basename(application))
                ("--module-name=%s.cloudml.deploy", basename(application))
                ("--")
                (entrypoint)
                (config_name)
                ("--environment=local"))

  gexec(gcloud(), arguments())
}

#' Predict a Model Locally
#'
#' @param model.dir The model directory.
#' @param json.instances Path to a JSON file, defining data
#'   to be used for prediction.
#' @param text.instances Path to a text file, defining data
#'   to be used for prediction.
#'
#' TODO
predict_local <- function(model.dir = getwd(),
                          json.instances = NULL,
                          text.instances = NULL)
{
  model.dir <- normalizePath(model.dir)

  # Add gcloud-specific arguments
  args <-
    (ShellArgumentsBuilder()
     ("beta")
     ("ml")
     ("local")
     ("predict")
     ("--model-dir=%s", model.dir))

  if (!is.null(json.instances))
    args("--json-instances=%s", json.instances)
  else if (!is.null(text.instances))
    args("--text-instances=%s", text.instances)
  else
    stop("one of 'json.instances' or 'text.instances' must be supplied")

  gexec(gcloud(), args())
}
