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
#' @export
train_local <- function(application = getwd(),
                        config      = "default",
                        ...)
{
  application <- scope_deployment(application)
  config_name <- config
  config <- cloudml::config(config = config)

  # resolve entrypoint
  dots <- list(...)
  entrypoint <- dots[["entrypoint"]] %||%
    config$train_entrypoint %||% "train.R"

  # move to application's parent directory
  owd <- setwd(dirname(application))
  on.exit(setwd(owd), add = TRUE)

  # serialize '...' as extra arguments to be merged
  # with the config file
  dots <- list(...)
  saveRDS(dots, file.path(application, ".cloudml_config.rds"))

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
