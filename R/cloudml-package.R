#' R Interface to Google Cloud ML
#'
#' This package provides an interface to Google's Cloud Machine Learning
#' platform.
NULL

.onLoad <- function(libname, pkgname) {

}

.onAttach <- function(libname, pkgname) {

}

.onUnload <- function(libpath) {

}

.onDetach <- function(libpath) {

}

gcloud <- function() {

  candidates <- list(
    function() Sys.which("gcloud"),
    function() "~/google-cloud-sdk/bin/gcloud"
  )

  for (candidate in candidates)
    if (file.exists(candidate()))
      return(normalizePath(candidate()))

  stop("failed to find 'gcloud' binary")
}
