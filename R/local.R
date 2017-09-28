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
  Sys.setenv(CLOUDML_EXECUTION_ENVIRONMENT = "local")
  on.exit(Sys.unsetenv("CLOUDML_EXECUTION_ENVIRONMENT"), add = TRUE)

  # prepare application for deployment
  application <- scope_deployment(application, config)

  # serialize overlay (these will be restored on deployment)
  ensure_directory("cloudml")
  overlay <- list(...)
  saveRDS(overlay, file = "cloudml/overlay.rds")

  # serialize config, entrypoint separately
  config <- list(application = application,
                 config = config,
                 entrypoint = entrypoint)
  saveRDS(config, file = "cloudml/config.rds")

  # move to application's parent directory
  setwd(dirname(application))

  # generate arguments for gcloud call
  arguments <- (MLArgumentsBuilder()
                ("local")
                ("train")
                ("--package-path=%s", basename(application))
                ("--module-name=%s.cloudml.deploy", basename(application))
                ("--")
                (R.home("bin/Rscript")))

  gexec(gcloud(), arguments())
}
