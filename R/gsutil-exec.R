# @keywords internal
# @rdname gcloud-paths
gsutil_binary <- function() {
  user_path <- user_setting("gsutil.binary.path")
  if (!is.null(user_path))
    return(normalizePath(user_path))

  candidates <- gcloud_path_candidates("gsutil")

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
