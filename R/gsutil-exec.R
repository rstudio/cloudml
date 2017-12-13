# @keywords internal
# @rdname gcloud-paths
gsutil_binary <- function() {
  user_path <- user_setting("gsutil.binary.path")
  if (!is.null(user_path))
    return(normalizePath(user_path))

  candidates <- c(
    function() Sys.which("gsutil"),
    function() "~/google-cloud-sdk/bin/gsutil"
  )

  if (.Platform$OS.type == "windows") {
    appdata <- normalizePath(Sys.getenv("localappdata"), winslash = "/")
    win_path <- file.path(appdata, "Google/Cloud SDK/google-cloud-sdk/bin/.cmd")
    if (file.exists(win_path))
      return(file.path(appdata, "Google/\"Cloud SDK\"/google-cloud-sdk/bin/gsutil.cmd"))
  }

  for (candidate in candidates)
    if (file.exists(candidate()))
      return(normalizePath(candidate()))

  stop("failed to find 'gsutil' binary")
}

#' Executes a Google Utils Command
#'
#' Executes a Google Utils command with the given parameters.
#'
#' @inheritParams gcloud_exec
#'
#' @param ... Parameters to use specified based on position.
#' @param args Parameters to use specified as a list.
#'
#' @keywords internal
#' @export
gsutil_exec <- function(..., args = NULL, echo = FALSE)
{
  if (is.null(args))
    args <- list(...)

  gexec(
    gsutil_binary(),
    args,
    echo = echo
  )
}
