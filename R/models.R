cloudml_model_exists <- function(gcloud, name) {

  arguments <- (MLArgumentsBuilder(gcloud)
                ("models")
                ("list"))

  output <- gcloud_exec(args = arguments())
  pasted <- paste(output$stdout, collapse = "\n")

  suppressWarnings({
    output <- readr::read_table2(pasted)
  })

  name %in% output$NAME
}

#' Deploy SavedModel to CloudML
#'
#' Deploys a SavedModel to CloudML model for online predictions.
#'
#' @inheritParams gcloud_config
#'
#' @param export_dir_base A string containing a directory containing an
#'   exported SavedModels. Consider using \code{tensorflow::export_savedmodel()}
#'   to export this SavedModel.
#' @param name The name for this model. Defaults to the current directory
#'   name.
#' @param version The version for this model. Versions start with a letter and
#'   contain only letters, numbers and underscores. Defaults to the current
#'   directory name.
#'
#' @export
cloudml_deploy <- function(
  export_dir_base,
  name =  NULL,
  version = NULL,
  gcloud = NULL) {

  default_name <- basename(normalizePath(getwd(), winslash = "/"))
  if (is.null(name)) name <- default_name
  if (is.null(version)) version <- default_name

  gcloud <- gcloud_config(gcloud)
  storage <- gs_ensure_storage(gcloud)

  if (is.null(gcloud$region)) gcloud$region <- gcloud_default_region("us-central1")

  if (!cloudml_model_exists(gcloud, name)) {
    arguments <- (MLArgumentsBuilder(gcloud)
                  ("models")
                  ("create")
                  (name)
                  ("--regions")
                  (gcloud$region))

    output <- gcloud_exec(args = arguments())
  }

  arguments <- (MLArgumentsBuilder(gcloud)
                ("versions")
                ("create")
                (as.character(version))
                ("--model")
                (name)
                ("--origin")
                (export_dir_base)
                ("--staging-bucket")
                (gs_bucket_from_gs_uri(storage)))

  output <- gcloud_exec(args = arguments())

  invisible(NULL)
}
