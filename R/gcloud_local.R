#' Train a Model Locally
#'
#' Train a model locally, using the \code{gcloud} command line
#' utility. This can be used as a testing bed for TensorFlow
#' applications which you want to later run on Google Cloud,
#' submitted using [train_cloud()].
#'
#' @template roxlate-application
#' @template roxlate-entrypoint
#' @template roxlate-config
#'
#' @export
train_local <- function(application = getwd(),
                        entrypoint  = "train.R",
                        config      = "default")
{
  # ensure application initialized
  initialize_application(application)
  owd <- setwd(dirname(application))
  on.exit(setwd(owd), add = TRUE)

  # generate arguments for gcloud call
  arguments <- (ShellArgumentsBuilder()
                ("beta")
                ("ml")
                ("local")
                ("train")
                ("--package-path=%s", basename(application))
                ("--module-name=%s.deploy", basename(application))
                ("--")
                (entrypoint)
                (config))

  system2(gcloud(), arguments())
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

  system2(gcloud(), args())
}
