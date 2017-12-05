#' Google Cloud Config
#'
#' Reads the Google Cloud config file.
#'
#' @param path Path to 'cloudml.yml' file; defaults to \code{getwd()}.
#'
gcloud_config <- function(path = getwd()) {

  file <- rprojroot::find_root_file(
    "cloudml.yml",
    criterion = "cloudml.yml",
    path = path
  )

  config <- yaml::yaml.load_file(file)

  # provide default account
  if (is.null(config$gcloud$account)) {
    config$gcloud$account <-
      capture.output(gcloud_exec("config", "get-value", "account"))
  }

  # validate required 'gcloud' fields
  gcloud <- config$gcloud
  for (field in c("project", "account")) {

    if (is.null(gcloud[[field]])) {
      fmt <- "[%s]: field '%s' is missing"
      stopf(fmt, as_aliased_path(file), field)
    }

    if (!is.character(gcloud[[field]])) {
      fmt <- "[%s]: field '%s' is not a string"
      stopf(fmt, as_aliased_path(file), field)
    }

  }

  gcloud
}
