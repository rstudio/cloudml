#' Copy files to / from Google Storage
#'
#' Use the `gsutil cp` command to copy data between your local file system and
#' the cloud, copy data within the cloud, and copy data between cloud storage
#' providers.
#'
#' @inheritParams gcloud_exec
#'
#' @param source
#'   The file to be copied. This can be either a path on the local
#'   filesystem, or a Google Storage URI (e.g. `gs://[BUCKET_NAME]/[FILENAME.CSV]`).
#'
#' @param destination
#'   The location where the `source` file should be copied to. This can be
#'   either a path on the local filesystem, or a Google Storage URI (e.g.
#'   `gs://[BUCKET_NAME]/[FILENAME.CSV]`).
#'
#' @param recursive
#'   Boolean; perform a recursive copy? This must be specified if you intend on
#'   copying directories.
#'
#' @export
gs_copy <- function(source, destination, recursive = FALSE, echo = TRUE) {

  arguments <- c(
    "-m",
    "cp",
    if (recursive) "-r",
    source,
    destination
  )

  gsutil_exec(args = arguments, echo = echo)
}


#' Synchronize content of two buckets/directories
#'
#' The `gs_rsync` function makes the contents under `destination` the same
#' as the contents under `source`, by copying any missing files/objects (or
#' those whose data has changed), and (if the `delete` option is specified)
#' deleting any extra files/objects. `source` must specify a directory, bucket,
#' or bucket subdirectory.
#'
#' @inheritParams gs_copy
#'
#' @param delete Delete extra files under `destination` not found under
#'   `source` By default extra files are not deleted.
#' @param recursive Causes directories, buckets, and bucket subdirectories to
#'   be synchronized recursively. If you neglect to use this option
#'   `gs_rsync()` will make only the top-level directory in the source and
#'   destination URLs match, skipping any sub-directories.
#' @param parallel Causes synchronization to run in parallel. This can
#'   significantly improve performance if you are performing operations on a
#'   large number of files over a reasonably fast network connection.
#' @param dry_run Causes rsync to run in "dry run" mode, i.e., just outputting
#'   what would be copied or deleted without actually doing any
#'   copying/deleting.
#' @param options Character vector of additional command line options to the
#'   gsutil rsync command (as specified at
#'   <https://cloud.google.com/storage/docs/gsutil/commands/rsync>).
#'
#' @export
gs_rsync <- function(source, destination,
                     delete = FALSE, recursive = FALSE,
                     parallel = TRUE, dry_run = FALSE,
                     options = NULL,
                     echo = TRUE) {

  if (!utils::file_test("-d", destination))
    dir.create(destination, recursive = TRUE)

  arguments <- c(
    if (parallel) "-m",
    "rsync",
    if (delete) "-d",
    if (recursive) "-r",
    if (dry_run) "-n",
    options,
    source,
    destination
  )

  gsutil_exec(args = arguments, echo = echo)
}



#' Get a local path to the contents of Google Storage bucket
#'
#' Provides a local filesystem interface to Google Storage buckets. Many
#' package functions accept only local filesystem paths as input (rather than
#' gs:// URLs). For these cases the `gcloud_path()` function will synchronize
#' gs:// buckets to the local filesystem and provide a local path interface
#' to their contents.
#'
#' @inheritParams gcloud_exec
#'
#' @param url Google Storage bucket URL (e.g. `gs://<your-bucket>`).
#' @param local_dir Local directory to synchonize Google Storage bucket(s) to.
#'
#' @return Local path to contents of bucket.
#'
#' @details If you pass a local path as the `url` it will be returned
#'   unmodified. This allows you to for example use a training flag for the
#'   location of data which points to a local directory during
#'   development and a Google Cloud bucket during cloud training.
#'
#' @export
gs_local_dir <- function(url, local_dir = "gs", echo = FALSE) {

  # return url unmodified for non google-storage URIs
  if (!is_gs_uri(url)) {
    url
  } else {

    # extract [BUCKET_NAME]/[OBJECT_NAME] and build local path
    object_path <- substring(url, nchar("gs://") + 1)
    local_path <- file.path(local_dir, object_path)

    # synchronize
    gs_rsync(url, local_path, delete = TRUE, recursive = TRUE, echo = echo)

    # return path
    local_path
  }
}

is_gs_uri <- function(file) {
  is.character(file) && grepl("^gs://.+$", file)
}

gs_ensure_storage <- function(gcloud) {
  storage <- getOption("cloudml.storage")
  if (is.null(storage)) {
    project <- gcloud[["project"]]
    if (!gcloud_project_has_bucket(project)) {
      gcloud_project_create_bucket(project)
    }
    storage <- file.path(gcloud_project_bucket(project), "r-cloudml")
  }

  storage
}
