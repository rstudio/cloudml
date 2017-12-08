#' Google Cloud Config
#'
#' Reads the Google Cloud config file.
#'
#' @param path Path to 'cloudml.yml' file; defaults to \code{getwd()}.
#'
gcloud_config <- function(path = getwd()) {

  file <- find_cloudml_config(path)
  if (!is.null(file)) {
    config <- yaml::yaml.load_file(file)
  } else {
    config <- list(gcloud = list(), cloudml = list())
  }

  # provide default account
  if (is.null(config$gcloud$account)) {
    config$gcloud$account <- gcloud_default_account()
    if (config$gcloud$account == "(unset)") {
      message("Google Cloud SDK has not yet been initialized")
      cat("\n")
      if (have_rstudio_terminal()) {
        message("Use the gcloud_init() function to initialize the SDK.")
        cat("\n")
      } else
        gcloud_init_message()
      stop("SDK not initialized")
    }
  }

  # provide default project
  if (is.null(config$gcloud$project)) {
    config$gcloud$project <- gcloud_default_project()
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

gcloud_default_account <- function() {
  trimws(gcloud_exec("config", "get-value", "account")$stdout)
}

gcloud_default_project <- function() {
  trimws(gcloud_exec("config", "get-value", "project")$stdout)
}

gcloud_project_has_bucket <- function(project = gcloud_default_project()) {
  buckets <- strsplit(gsutil_exec("ls", "-p", project)$stdout, "\n")[[1]]
  gcloud_project_bucket(project, TRUE) %in% buckets
}

gcloud_project_create_bucket <- function(project = gcloud_default_project()) {
  gsutil_exec("mb", "-p", project, gcloud_project_bucket(project))
}

gcloud_project_bucket <- function(project = gcloud_default_project(),
                                  trailing_slash = FALSE) {
  bucket <- sprintf("gs://%s", project)
  if (trailing_slash)
    bucket <- paste0(bucket, "/")
  bucket
}

