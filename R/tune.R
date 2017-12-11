#' Tune hyperparameters on Cloud ML
#'
#' @inheritParams cloudml_train
#'
#' @export
cloudml_tune <- function(file = "train.R",
                         config = "cloudml",
                         flags = NULL,
                         hypertune = "hypertune.yml")
{
  # validate hyperparameters path
  application <- getwd()
  if (!file.exists(file.path(application, hypertune))) {
    fmt <- "no tuning configuration file exists at path '%s'"
    stopf(fmt, file.path(application, hypertune))
  }

  # delegate to cloudml_train
  cloudml_train(file = file,
                config = config,
                flags = flags,
                hypertune = hypertune)
}
