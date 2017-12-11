#' Tune hyperparameters on Cloud ML
#'
#' @inheritParams cloudml_train
#'
#' @seealso [job_trials()]
#'
#' @export
cloudml_tune <- function(file = "train.R",
                         config = "cloudml",
                         scale_tier = c("basic", "basic-gpu", "basic-tpu"),
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
                scale_tier = scale_tier,
                flags = flags,
                hypertune = hypertune)
}
