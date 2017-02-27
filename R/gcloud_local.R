#' Train a Model Locally
#'
#' @template roxlate-application
#' @template roxlate-arguments
#'
#' @export
cloudml_local_train <- function(application = getwd(),
                                arguments = list())
{
  owd <- setwd(dirname(application))
  on.exit(setwd(owd), add = TRUE)

  # generate arguments for gcloud call
  args <-
    (ShellArgumentsBuilder()
     ("beta")
     ("ml")
     ("local")
     ("train")
     ("--package-path=%s", basename(application))
     ("--module-name=%s.deploy", basename(application))
     ("--"))

  if (length(arguments))
    for (argument in arguments)
      args(argument)

  arguments <- args()
  system2(gcloud(), arguments)
}

#' Predict a Model Locally
#'
#' @param model.dir The model directory.
#' @param json.instances Path to a JSON file, defining data
#'   to be used for prediction.
#' @param text.instances Path to a text file, defining data
#'   to be used for prediction.
#'
#' @export
cloudml_local_predict <- function(model.dir = getwd(),
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
