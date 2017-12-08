# required R packages
CRAN <- c("RCurl", "devtools", "readr", "knitr")
GITHUB <- list(
  list(uri = "tidyverse/purrr",      ref = NULL),
  list(uri = "tidyverse/modelr",     ref = NULL),
  list(uri = "rstudio/tensorflow",   ref = NULL),
  list(uri = "rstudio/cloudml",      ref = NULL),
  list(uri = "rstudio/keras",        ref = NULL),
  list(uri = "rstudio/tfruns",       ref = NULL),
  list(uri = "rstudio/tfestimators", ref = NULL),
  list(uri = "rstudio/packrat",      ref = NULL)
)

# validate resources
r_version <- paste(R.Version()$major, R.Version()$minor, sep = ".")
if (compareVersion(r_version, "3.4.0") < 0)
  stop("Found R version ", r_version, " but 3.4.0 or newer is expected.")

# save repository + download methods
repos <- getOption("repos")
download.file.method <- getOption("download.file.method")
download.file.extra  <- getOption("download.file.extra")

# emit warnings as they occur
options(warn = 1)

on.exit(
  options(
    repos = repos,
    download.file.method = download.file.method,
    download.file.extra = download.file.extra
  ),
  add = TRUE
)

# set an appropriate downloader
if (nzchar(Sys.which("curl"))) {
  options(
    repos = c(CRAN = "https://cran.rstudio.com"),
    download.file.method = "curl",
    download.file.extra  = "-L -f"
  )
} else if (nzchar(Sys.which("wget"))) {
  options(
    repos = c(CRAN = "https://cran.rstudio.com"),
    download.file.method = "wget",
    download.file.extra  = NULL
  )
} else {
  options(repos = c(CRAN = "http://cran.rstudio.com"))
}

# source a file 'dependencies.R', if it exists
if (file.exists("dependencies.R"))
  source("dependencies.R")

retrieve_packrat_packages <- function() {
  # attempt to restore using a packrat lockfile
  if (file.exists("packrat/packrat.lock")) {
    message("Restoring package using packrat lockfile")

    # ensure packrat is installed
    if (!"packrat" %in% rownames(installed.packages()))
      install.packages("packrat")

    # attempt a project restore
    packrat::restore()
  }
}

# discover available R packages
installed <- rownames(installed.packages())

if (!"yaml" %in% installed) install.packages("yaml")


config <- yaml::yaml.load_file("cloudml.yml")
cloudml <- config$cloudml

cache <- cloudml[["cache"]]
if (is.null(cache)) {
  cache <- file.path(cloudml[["storage"]], "cache")
  message(paste0("Cache entry not found, defaulting to: ", cache))
} else {
  message(paste0("Cache entry found: ", cache))
}

use_packrat <- cloudml[["packrat"]]
if (is.null(use_packrat)) {
  use_packrat <- TRUE
}

get_cached_packages <- function () {
  cached_entries <- system2("gsutil", c("ls", cache), stdout = TRUE)
  as.character(lapply(strsplit(basename(cached_entries), "\\."), function(e) e[[1]]))
}

store_cached_packages <- function () {
  if (identical(cache, FALSE)) return()

  cached_entries <- get_cached_packages()
  installed <- rownames(installed.packages())

  for (pkg in installed) {
    if (!pkg %in% cached_entries) {
      source <- system.file("", package = pkg)
      compressed <- file.path(tempdir(), paste0(pkg, ".tar"))

      message(paste0("Compressing '", pkg, "' package to ", compressed, " cache."))
      system2("tar", c("-cf", compressed, "-C", source, "."))

      target <- file.path(cache, paste0(pkg, ".tar"))

      message(paste0("Adding '", compressed, "' to ", target, " cache."))
      system(paste("gsutil", "cp", shQuote(compressed), shQuote(target)))
    }
  }
}

retrieve_cached_packages <- function() {
  if (identical(cache, FALSE)) return()

  compressed <- file.path(tempdir(), "cache/")
  if (!file_test("-d", compressed)) dir.create(compressed, recursive = TRUE)

  remote_path <- file.path(cache, "*")

  message(paste0("Retrieving packages from ", remote_path, " cache into ", compressed, "."))
  system(paste("gsutil", "-m", "cp", "-r", shQuote(remote_path), shQuote(compressed)))

  target <- .libPaths()[[1]]
  lapply(dir(compressed, full.names = TRUE, pattern = ".tar"), function(tar_file) {
    target_package <- strsplit(basename(tar_file), "\\.")[[1]][[1]]
    target_path <- file.path(target, target_package)

    if (!file_test("-d", target_path)) dir.create(target_path, recursive = TRUE)

    message(paste0("Restoring package from ", tar_file, " cache into ", target_path, "."))
    system2("tar", c("-xf", tar_file, "-C", target_path))
  })

  invisible(NULL)
}

# make use of cache
retrieve_cached_packages()

# discover available R packages
installed <- rownames(installed.packages())

# install required CRAN packages
for (pkg in CRAN) {
  if (pkg %in% installed)
    next
  install.packages(pkg)
}

# install required GitHub packages
for (entry in GITHUB) {
  if (basename(entry$uri) %in% installed)
    next
  devtools::install_github(entry$uri, ref = entry$ref)
}

if (use_packrat)
  retrieve_packrat_packages();

store_cached_packages()

# Training ----

library(cloudml)

# read deployment information
deploy <- readRDS("cloudml/deploy.rds")

# source entrypoint
run_dir <- file.path("runs", deploy$id)
tfruns::training_run(file = deploy$entrypoint,
                     context = deploy$environment,
                     flags = deploy$overlay,
                     encoding = "UTF-8",
                     echo = TRUE,
                     view = FALSE,
                     run_dir = run_dir)

tf_config <- jsonlite::fromJSON(Sys.getenv("TF_CONFIG", "{}"))

trial_id <- NULL
if (!is.null(deploy$overlay$hypertune) && !is.null(tf_config$task)) {
  trial_id <- tf_config$task$trial
}

# upload run directory to requested bucket (if any)
storage <- cloudml[["storage"]]
if (is.character(storage)) {
  source <- run_dir
  target <- do.call("file.path", as.list(c(storage, run_dir, trial_id)))
  system(paste(gsutil_path(), "cp", "-r", shQuote(source), shQuote(target)))
}
