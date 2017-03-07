#' Generate Predictions with a Model Locally
#'
#' Generate predictions using a TensorFlow model saved on disk.
#'
#' @param model_dir
#'   The path to a model directory, or a jobs directory containing
#'   an exported model directory.
#'
#' @param data
#'   The dataset to be used for prediction.
#'
#' @export
predict_local <- function(model_dir, data) {
  model_dir <- discover_model_dir(model_dir)

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

#' @export
as_json_instances.default <- function(data) {
  jsonlite::toJSON(data, auto_unbox = TRUE)
}

discover_model_dir <- function(dir) {

  # if we have a 'saved_model.pb' or 'saved_model.pbtxt' in
  # this directory, then just use it
  candidates <- c(
    "saved_model.pb",
    "saved_model.pbtxt"
  )

  for (candidate in candidates)
    if (file.exists(file.path(dir, candidate)))
      return(dir)

  # otherwise, crawl directory for one of these files
  re_candidates <- sprintf("(?:%s)", paste(candidates, collapse = "|"))
  files <- list.files(dir,
                      pattern = re_candidates,
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
