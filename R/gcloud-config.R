#' Google Cloud Config
#'
#' Reads the Google Cloud config file.
#'
#' @param gcloud A list or \code{YAML} file with optional 'account', 'project',
#'   and 'configuration' fields used to configure the GCloud environemnt.
#'
gcloud_config <- function(gcloud = NULL) {

  if (is.list(gcloud)) {
    config <- gcloud
  } else if (is.null(gcloud)) {
    path <- getwd()
    gcloud <- find_config_file(path, "gcloud.yml")
    config <- yaml::yaml.load_file(gcloud)
  } else if (is.character(gcloud)) {
    if (file.exists(gcloud))
      config <- yaml::yaml.load_file(gcloud)
    else
      stop("gcloud config file '", gcloud, "' not found")
  } else {
    config <- list()
  }

  # provide default account
  if (is.null(config$account)) {
    config$account <- gcloud_default_account()
    if (config$account == "(unset)") {
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
  if (is.null(config$project)) {
    config$project <- gcloud_default_project()
  }

  # validate required 'gcloud' fields
  for (field in c("project", "account")) {

    if (is.null(config[[field]])) {
      fmt <- "[%s]: field '%s' is missing"
      stopf(fmt, as_aliased_path(file), field)
    }

    if (!is.character(config[[field]])) {
      fmt <- "[%s]: field '%s' is not a string"
      stopf(fmt, as_aliased_path(file), field)
    }

  }

  config
}

gcloud_default_account <- function() {
  trimws(gcloud_exec("config", "get-value", "account")$stdout)
}

gcloud_default_project <- function() {
  trimws(gcloud_exec("config", "get-value", "project")$stdout)
}

gcloud_default_region <- function() {
  trimws(
    gexec(
      gcloud_binary(),
      c("config", "get-value", "region"),
      echo = FALSE,
      throws = FALSE
    )$stdout
  )
}

gcloud_project_has_bucket <- function(project = gcloud_default_project()) {
  buckets <- strsplit(gsutil_exec("ls", "-p", project)$stdout, "\r|\n")[[1]]
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

