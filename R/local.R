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
                        ...)
{
  Sys.setenv(CLOUDML_EXECUTION_ENVIRONMENT = "local")
  on.exit(Sys.unsetenv("CLOUDML_EXECUTION_ENVIRONMENT"), add = TRUE)

  # prepare application for deployment
  application <- scope_deployment(application, config)

  # resolve runtime configuration and serialize
  # within the application's cloudml directory
  overlay <- resolve_train_overlay(application, list(...), config)
  ensure_directory("cloudml")
  saveRDS(overlay, file = "cloudml/overlay.rds")

  # move to application's parent directory
  setwd(dirname(application))

  # generate arguments for gcloud call
  arguments <- (MLArgumentsBuilder()
                ("local")
                ("train")
                ("--package-path=%s", basename(application))
                ("--module-name=%s.cloudml.deploy", basename(application))
                ("--")
                ("--cloudml-entrypoint=%s", overlay$entrypoint)
                ("--cloudml-config=%s", config)
                ("--cloudml-environment=local"))

  gexec(gcloud(), arguments())
}
