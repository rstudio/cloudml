#' Tune hyperparameters on Cloud ML
#'
#' @inheritParams cloudml_train
#' @param hyperparameters
#'   Path to the job configuration file. The file should be
#'   a YAML document containing a Job resource as defined in
#'   the API (all fields are optional):
#'   https://cloud.google.com/ml/reference/rest/v1/projects.jobs
cloudml_tune <- function(application = getwd(),
                         config = "cloudml",
                         hyperparameters = "hyperparameters.yml",
                         ...)
{
  # validate hyperparameters path
  if (!file.exists(file.path(application, hyperparameters))) {
    fmt <- "no configuration file exists at path '%s'"
    stopf(fmt, file.path(application, hyperparameters))
  }

  # delegate to cloudml_train
  cloudml_train(application = application,
                config = config,
                hyperparameters = hyperparameters,
                ...)
}
