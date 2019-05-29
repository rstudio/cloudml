cloudml_model_exists <- function(gcloud, name) {

  arguments <- (MLArgumentsBuilder(gcloud)
                ("models")
                ("list")
                ("--format=json"))

  output <- gcloud_exec(args = arguments(), echo = FALSE)
  pasted <- paste(output$stdout, collapse = "\n")

  output_parsed <- jsonlite::fromJSON(pasted)

  !is.null(output_parsed$name) && name %in% basename(output_parsed$name)
}

#' Deploy SavedModel to CloudML
#'
#' Deploys a SavedModel to CloudML model for online predictions.
#'
#' @inheritParams cloudml_train
#'
#' @param export_dir_base A string containing a directory containing an
#'   exported SavedModels. Consider using [tensorflow::export_savedmodel()]
#'   to export this SavedModel.
#' @param name The name for this model (required)
#' @param version The version for this model. Versions start with a letter and
#'   contain only letters, numbers and underscores. Defaults to name_1
#' @param region The region to be used to deploy this model.
#'
#' @seealso [cloudml_predict()]
#'
#' @family CloudML functions
#' @export
cloudml_deploy <- function(
  export_dir_base,
  name,
  version = paste0(name, "_1"),
  region = NULL,
  config = NULL) {

  cloudml <- cloudml_config(config)
  gcloud <- gcloud_config()
  storage <- gs_ensure_storage(gcloud)

  if (is.null(region)) region <- gcloud_default_region()

  if (!cloudml_model_exists(gcloud, name)) {
    arguments <- (MLArgumentsBuilder(gcloud)
                  ("models")
                  ("create")
                  (name)
                  ("--regions=%s", region))

    gcloud_exec(args = arguments(), echo = FALSE)
  }

  model_dest <- sprintf(
    "%s/models/%s",
    storage,
    timestamp_string()
  )

  gs_copy(export_dir_base, model_dest, recursive = TRUE)

  arguments <- (MLArgumentsBuilder(gcloud)
                ("versions")
                ("create")
                (as.character(version))
                ("--model=%s", name)
                ("--origin=%s", model_dest)
                ("--runtime-version=%s", cloudml$trainingInput$runtimeVersion %||% "1.13"))

  gcloud_exec(args = arguments(), echo = FALSE)

  message("Model created and available in https://console.cloud.google.com/mlengine/models/", name)

  invisible(NULL)
}

#' Perform Prediction over a CloudML Model.
#'
#' Perform online prediction over a CloudML model, usually, created using
#' [cloudml_deploy()]
#'
#' @inheritParams cloudml_deploy
#'
#' @param instances A list of instances to be predicted. While predicting
#'   a single instance, list wrapping this single instance is still expected.
#' @param verbose Should additional information be reported?
#'
#' @seealso [cloudml_deploy()]
#'
#' @family CloudML functions
#' @export
cloudml_predict <- function(
  instances,
  name,
  version = paste0(name, "_1"),
  verbose = FALSE) {

  default_name <- basename(normalizePath(getwd(), winslash = "/"))
  if (is.null(name)) name <- default_name
  if (is.null(version)) version <- default_name

  gcloud <- gcloud_config()

  # CloudML CLI does not expect valid JSON but rather a one line per JSON instance.
  # See https://cloud.google.com/ml-engine/docs/online-predict#formatting_your_input_for_online_prediction

  pseudo_json_file <- tempfile(fileext = ".json")
  all_json <- lapply(instances, function(instance) {
    as.character(jsonlite::toJSON(instance, auto_unbox = TRUE))
  })
  writeLines(paste(all_json, collapse = "\n"), pseudo_json_file)

  if (identical(verbose, TRUE)) {
    message("Prediction Request:")
    message("")
    sapply(all_json, message)
    message("")
  }

  arguments <- (MLArgumentsBuilder(gcloud)
                ("predict")
                ("--model=%s", name)
                ("--version=%s", as.character(version))
                ("--json-instances=%s", pseudo_json_file)
                ("--format=%s", "json"))

  output <- gcloud_exec(args = arguments(), echo = FALSE)

  json_raw <- output$stdout
  json_parsed <- jsonlite::fromJSON(json_raw, simplifyDataFrame = FALSE)
  if (!is.null(json_parsed$error))
    stop(json_parsed$error)

  class(json_parsed) <- c(class(json_parsed), "cloudml_predictions")

  if (getOption("cloudml.prediction.diagnose", default = FALSE))
    list(
      request = all_json,
      response = json_raw
    )
  else
    json_parsed
}

#' @export
print.cloudml_predictions <- function(x, ...) {
  predictions <- x$predictions
  for (index in seq_along(predictions)) {
    prediction <- predictions[[index]]
    if (length(predictions) > 1)
      message("Prediction ", index, ":")

    print(prediction)
  }
}
