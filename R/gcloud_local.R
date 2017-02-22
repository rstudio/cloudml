#' Train a Model Locally
#'
#' @template roxlate-application
#' @template roxlate-arguments
#'
#' @export
cloudml_local_train <- function(application = getwd(),
                                arguments = list())
{
  application <- normalizePath(application)
  deployment_dir <- generate_deployment_dir(application)

  owd <- setwd(deployment_dir)
  on.exit(setwd(owd), add = TRUE)

  # Add gcloud-specific arguments
  args <-
    (Arguments()
     ("beta")
     ("ml")
     ("local")
     ("train")
     ("--package-path %s", basename(application))
     ("--module-name %s.deploy", basename(application))
     ("--"))

  if (length(arguments))
    for (argument in arguments)
      args(argument)

  arguments <- args()
  system2(gcloud(), arguments)
}

#' Predict a Model Locally
#'
#' @template roxlate-application
#' @template roxlate-entrypoint
#' @template roxlate-arguments
#'
#' @export
gcloud_local_predict <- function(application = getwd(),
                                 arguments = list())
{
  # TODO
}
