#' Discover the gcloud Executable
#'
#' Discover the path of the `gcloud` executable.
#'
#' The path to the `gcloud` executable can be explicitly
#' specified, using the `GCLOUD_BINARY_PATH` environment
#' variable, or the `gcloud.binary.path` \R option.
#'
#' When none of the above are set, `gcloud` will instead be
#' discovered either on the system `PATH`, or by looking
#' in the default folders used for the Google Cloud SDK
#' installation.
#'
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

#' Discover the path of the `gsutl` executable.
#'
#' The path to the `gsutl` executable can be explicitly
#' specified, using the `GSUTIL_BINARY_PATH` environment
#' variable, or the `gsutil.binary.path` \R option.
#'
#' When none of the above are set, `gsutil` will instead be
#' discovered either on the system `PATH`, or by looking
#' in the default folders used for the Google Cloud SDK
#' installation.
#'
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

#' Copy a file from Google Storage to the local system
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


#' Get a path to a data file within Google Storage
#'
#' When running on Google Cloud the path is returned unchanged. When running in
#' other contexts the file is copied to the local system and a path to the local
#' file is returned. If a plain filesystem path is passed then it is also
#' returned unchanged.
#'
#' @inheritParams gs_copy
#'
#' @return Path to data file (may be local or remote depending on the execution
#'   context).
#'
#' @importFrom utils download.file
#'
#' @export
gs_data <- function(uri) {
  if (is_gcloud() || !is_gs_uri(uri))
    uri
  else {
    # extract [BUCKET_NAME]/[OBJECT_NAME] and build local path
    object_path <- substring(uri, nchar("gs://") + 1)
    local_path <- file.path("gs_data", object_path)

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



is_gcloud <- function() {
  identical(Sys.getenv("GCLOUD_EXECUTION_ENVIRONMENT"), "1")
}

with_gcloud_environment <- function(expr) {
  withr::with_envvar(c(GCLOUD_EXECUTION_ENVIRONMENT = 1), expr)
}


is_gs_uri <- function(file) {
  is.character(file) && grepl("^gs://.+$", file)
}


