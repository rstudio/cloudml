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

staging_bucket <- function() {
  user_setting("gcloud.bucket", "")
}
