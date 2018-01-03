cloudml_model_exists <- function(gcloud, name) {

  arguments <- (MLArgumentsBuilder(gcloud)
                ("models")
                ("list")
                ("--format=json"))

  output <- gcloud_exec(args = arguments())
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
#'   exported SavedModels. Consider using \code{tensorflow::export_savedmodel()}
#'   to export this SavedModel.
#' @param name The name for this model (required)
#' @param version The version for this model. Versions start with a letter and
#'   contain only letters, numbers and underscores. Defaults to name_1
#'
#' @seealso [cloudml_predict()]
#'
#' @export
cloudml_deploy <- function(
  export_dir_base,
  name,
  version = paste0(name, "_1"),
  cloudml = NULL,
  gcloud = NULL) {

  cloudml <- cloudml_config(cloudml)
  gcloud <- gcloud_config(gcloud)
  storage <- gs_ensure_storage(gcloud)

  if (is.null(gcloud$region)) gcloud$region <- gcloud_default_region()

  if (!cloudml_model_exists(gcloud, name)) {
    arguments <- (MLArgumentsBuilder(gcloud)
                  ("models")
                  ("create")
                  (name)
                  ("--regions=%s", gcloud$region))

    gcloud_exec(args = arguments())
  }

  arguments <- (MLArgumentsBuilder(gcloud)
                ("versions")
                ("create")
                (as.character(version))
                ("--model=%s", name)
                ("--origin=%s", export_dir_base)
                ("--staging-bucket=%s", gs_bucket_from_gs_uri(storage))
                ("--runtime-version=%s", cloudml$trainingInput$runtimeVersion %||% "1.4"))

  gcloud_exec(args = arguments())

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
#'
#' @seealso [cloudml_deploy()]
#'
#' @export
cloudml_predict <- function(
  instances,
  name,
  version = paste0(name, "_1"),
  gcloud = NULL) {

  default_name <- basename(normalizePath(getwd(), winslash = "/"))
  if (is.null(name)) name <- default_name
  if (is.null(version)) version <- default_name

  gcloud <- gcloud_config(gcloud)

  # CloudML CLI does not expect valid JSON but rather a one line per JSON instance.
  # See https://cloud.google.com/ml-engine/docs/online-predict#formatting_your_input_for_online_prediction

  pseudo_json_file <- tempfile(fileext = ".json")
  all_json <- lapply(instances, function(instance) {
    as.character(jsonlite::toJSON(instance))
  })
  writeLines(paste(all_json, collapse = "\n"), pseudo_json_file)

  arguments <- (MLArgumentsBuilder(gcloud)
                ("predict")
                ("--model=%s", name)
                ("--version=%s", as.character(version))
                ("--json-instances=%s", pseudo_json_file)
                ("--format=%s", "json"))

  output <- gcloud_exec(args = arguments())

  json <- jsonlite::fromJSON(output$stdout)
  if (!is.null(json$error))
    stop(json$error)

  json
}
