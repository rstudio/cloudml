#' Generate Predictions with a Model Locally
#'
#' Generate predictions using a TensorFlow model saved on disk.
#'
#' @param dir
#'   The path to a model directory, or a jobs directory containing
#'   an exported model directory.
#'
#' @param data
#'   The dataset to be used for prediction.
#'
#' @export
predict_local <- function(dir, data) {

  # discover model dir
  model_dir <- discover_model_dir(dir)

  # convert to JSON
  json <- as.character(as_json_instances(data))

  # write to tempfile
  tempfile <- tempfile(fileext = ".json")
  writeLines(json, con = tempfile, useBytes = TRUE)


  arguments <- (MLArgumentsBuilder()
                ("local")
                ("predict")
                ("--model-dir=%s", model_dir)
                ("--json-instances=%s", tempfile))

  output <- gexec(gcloud(), arguments(), stdout = TRUE)
  yaml::yaml.load(paste(output, collapse = "\n"))
}

as_json_instances <- function(data) {
  UseMethod("as_json_instances")
}

#' @export
as_json_instances.data.frame <- function(data) {
  lapply(seq_len(nrow(data)), function(i) {
    row <- as.list(data[i, ])
    jsonlite::toJSON(row, auto_unbox = TRUE)
  })
}

discover_model_dir <- function(dir) {

  files <- list.files(dir,
                      pattern = "saved_model.pb(?:txt)?",
                      full.names = TRUE,
                      recursive = TRUE)

  # report failure to discover any model directory
  if (length(files) == 0) {
    fmt <- "failed to discover model directory within directory '%s'"
    stopf(fmt, dir)
  }

  # warn if we found multiple model directories
  if (length(files) != 1) {
    fmt <- "multiple models discovered; using model at path '%s'"
    warnf(fmt, dirname(files[[1]]))
    files <- files[[1]]
  }

  # return discovered directory
  dirname(files)
}

# TODO: Consider whether we should route through the 'google.cloud.ml.prediction' package?
# predict_local <- function(dir, instances) {
#   # TODO: route this through the gcloud APIs
#   cloudml <- import("google.cloud.ml")
#   prediction <- cloudml$prediction
#
#   # provide data as JSON
#   instances <- resolve_instances(instances)
#
#   prediction$local_predict(
#     model_dir = dir,
#     instances = instances
#   )
# }
