#' Train a model locally
#'
#' Train a model locally, using the `gcloud` command line
#' utility. This can be used as a testing bed for TensorFlow
#' applications which you want to later run on Google Cloud,
#' submitted using [cloudml_train()].
#'
#' @inheritParams cloudml_train
#'
#' @export
local_train <- function(application = getwd(),
                        config      = "default",
                        entrypoint  = "train.R",
                        ...)
{
  # prepare application for deployment
  id <- unique_job_name(application, config)
  overlay <- list(...)
  deployment <- scope_deployment(
    id = id,
    application = application,
    context = "local",
    config = config,
    overlay = overlay,
    entrypoint = entrypoint
  )

  # move to application's parent directory
  directory <- deployment$directory
  setwd(dirname(directory))

  # generate arguments for gcloud call
  arguments <- (MLArgumentsBuilder()
                ("local")
                ("train")
                ("--package-path=%s", basename(directory))
                ("--module-name=%s.cloudml.deploy", basename(directory))
                ("--")
                (R.home("bin/Rscript")))

  gcloud_exec(args = arguments())
}
