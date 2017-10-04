#' Discover paths of gcloud executables.
#'
#' Discover the paths of the `gcloud` and `gsutil` executables.
#'
#' @details
#' The path to the `gcloud` executable can be explicitly
#' specified, using the `GCLOUD_BINARY_PATH` environment
#' variable, or the `gcloud.binary.path` \R option.
#'
#' The path to the `gsutil` executable can be explicitly
#' specified, using the `GSUTIL_BINARY_PATH` environment
#' variable, or the `gsutil.binary.path` \R option.
#'
#' When none of the above are set, locations will instead be
#' discovered either on the system `PATH`, or by looking
#' in the default folders used for the Google Cloud SDK
#' installation.
#'
#' @name gcloud-paths
#' @keywords internal
#' @export
gcloud <- function() {

  user_path <- user_setting("gcloud.binary.path")
  if (!is.null(user_path))
    return(normalizePath(user_path))

  candidates <- c(
    function() Sys.which("gcloud"),
    function() "~/google-cloud-sdk/bin/gcloud"
  )

  for (candidate in candidates)
    if (file.exists(candidate()))
      return(normalizePath(candidate()))

  stop("failed to find 'gcloud' binary")
}

#' @keywords internal
#' @rdname gcloud-paths
#' @export
gsutil <- function() {
  user_path <- user_setting("gsutil.binary.path")
  if (!is.null(user_path))
    return(normalizePath(user_path))

  candidates <- c(
    function() Sys.which("gsutil"),
    function() "~/google-cloud-sdk/bin/gsutil"
  )

  for (candidate in candidates)
    if (file.exists(candidate()))
      return(normalizePath(candidate()))

  stop("failed to find 'gsutil' binary")
}

#' Copy files from Google Storage
#'
#' @param uri Google storage URI (e.g. `gs://[BUCKET_NAME]/[FILENAME.CSV]`)
#' @param destination Path to copy file to on the local filesystem
#' @param overwrite Overwrite an existing file of the same name
#'
#' @export
gs_copy <- function(uri, destination, overwrite = FALSE) {
  gsutil <- gsutil()
  if (!file.exists(destination) || overwrite) {
    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    system(paste(gsutil, "cp", shQuote(uri), shQuote(destination)))
  }
  destination
}


#' Get a path to data within Google Storage
#'
#' When running on Google Cloud the path is returned unchanged. When running in
#' other contexts the file is copied to the local system and a path to the local
#' file is returned. If a plain filesystem path is passed then it is also
#' returned unchanged.
#'
#' @inheritParams gs_copy
#' @param local_dir Local directory to copy files into
#'
#' @return Path to data file (may be local or remote depending on the execution
#'   context).
#'
#' @export
gs_data <- function(uri, local_dir = "gs") {
  if (!is_gs_uri(uri))
    uri
  else {
    # extract [BUCKET_NAME]/[OBJECT_NAME] and build local path
    object_path <- substring(uri, nchar("gs://") + 1)
    local_path <- file.path(local_dir, object_path)

    # download if necessary
    if (!file.exists(local_path)) {

      # create the directory if necessary
      local_dir <- dirname(local_path)
      if (!utils::file_test("-d", local_dir))
        dir.create(local_dir, recursive = TRUE)

      # first attempt download via public api endpoint
      public_url <- paste0("https://storage.googleapis.com/", object_path)
      result <- tryCatch(suppressWarnings(download.file(public_url, local_path)),
                         error = function(e) 1)

      # if that failed then try gs_copy (which requires auth)
      if (result != 0)
        gs_copy(uri, local_path)
    }

    # return path
    local_path
  }
}

is_gs_uri <- function(file) {
  is.character(file) && grepl("^gs://.+$", file)
}

cloudml_config <- function(path = getwd()) {

  file <- rprojroot::find_root_file(
    "cloudml.yml",
    criterion = "cloudml.yml",
    path = path
  )

  config <- yaml::yaml.load_file(file)
  config$cloudml

}

gcloud_config <- function(path = getwd()) {

  file <- rprojroot::find_root_file(
    "cloudml.yml",
    criterion = "cloudml.yml",
    path = path
  )

  config <- yaml::yaml.load_file(file)

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
