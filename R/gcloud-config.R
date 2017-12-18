# Google Cloud Config
gcloud_config <- function(gcloud = NULL) {

  if (is.list(gcloud)) {
    config <- gcloud
  } else if (is.null(gcloud)) {
    path <- getwd()
    gcloud <- find_config_file(path, "gcloud.yml")
    if (!is.null(gcloud))
      config <- yaml::yaml.load_file(gcloud)
    else
      config <- list()
  } else if (is.character(gcloud)) {
    if (file_test("-f", gcloud))
      config <- yaml::yaml.load_file(gcloud)
    else
      stop("gcloud config file '", gcloud, "' not found")
  } else {
    config <- list()
  }

  # provide defaults if there is no named configuration
  if (is.null(config$configuration)) {

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

