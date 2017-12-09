# required R packages
CRAN <- c(
  "RCurl",
  "devtools",
  "readr",
  "knitr"
)

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
if (utils::compareVersion(r_version, "3.4.0") < 0)
  warning("Found R version ", r_version, " but 3.4.0 or newer is expected.")

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

retrieve_packrat_packages <- function(cache_path) {
  # attempt to restore using a packrat lockfile
  if (file.exists("packrat/packrat.lock")) {
    message("Restoring package using packrat lockfile")
    message("Packrat lockfile:\n", paste(readLines("packrat/packrat.lock"), collapse = "\n"))

    if (!"devtools" %in% rownames(installed.packages()))
      install.packages("devtools")

    # ensure packrat is installed
    # need packrat devel to avoid 'Error: contains a blank line' in tfruns
    if (!"packrat" %in% rownames(installed.packages()))
      devtools::install_github("rstudio/packrat")

    Sys.setenv(
      R_PACKRAT_CACHE_DIR = cache_path
    )

    options(packrat.verbose.cache = TRUE,
            packrat.connect.timeout = 10)

    packrat::set_opts(
      auto.snapshot = FALSE,
      use.cache = TRUE,
      project = getwd(),
      persist = FALSE
    )

    # attempt a project restore
    packrat::restore(overwrite.dirty = TRUE,
                     prompt = FALSE,
                     restart = FALSE)
    packrat::on()
  }
}

# discover available R packages
installed <- rownames(installed.packages())

if (!"yaml" %in% installed) install.packages("yaml")


config <- yaml::yaml.load_file("cloudml.yml")
cloudml <- config$cloudml

cache <- cloudml[["cache"]]
cache_enabled <- !identical(cloudml[["cache"]], FALSE)

if (is.null(cache)) {
  cache <- file.path(cloudml[["storage"]], "cache")
  message(paste0("Cache entry not found, defaulting to: ", cache))
} else {
  message(paste0("Cache entry found: ", cache))
}

# add linux distro and r version to cache
if (file.exists("/etc/issue")) {
  linux_info <- gsub("[^a-zA-Z0-9 ]| *\\\\[a-z] *", "", readLines("/etc/issue")[[1]])
  linux_version <- tolower(gsub("[ .]", "_", linux_info))

  r_version <- tolower(gsub("[ .]", "_", paste("r", R.version$minor, R.version$major)))
  cache <- file.path(cache, linux_version, r_version)

  message(paste0("Versioning cache as: ", cache))
}

use_packrat <- !identical(cloudml[["packrat"]], FALSE)

get_cached_bundles <- function (source) {
  cached_entries <- system2("gsutil", c("ls", source), stdout = TRUE)
  as.character(lapply(strsplit(basename(cached_entries), "\\."), function(e) e[[1]]))
}

store_cached_data <- function (source, destination, replace_all = FALSE) {
  cached_entries <- get_cached_bundles(destination)
  installed <- rownames(installed.packages())

  for (pkg in dir(source)) {
    if (!pkg %in% cached_entries || replace_all) {
      source_entry <- file.path(source, pkg)
      compressed <- file.path(tempdir(), paste0(pkg, ".tar"))

      message(paste0("Compressing '", pkg, "' package to ", compressed, " cache."))
      system2("tar", c("-cf", compressed, "-C", source_entry, "."))

      target <- file.path(destination, paste0(pkg, ".tar"))

      message(paste0("Adding '", compressed, "' to ", target, " cache."))
      system(paste("gsutil", "cp", shQuote(compressed), shQuote(target)))
    }
  }
}

retrieve_cached_data <- function(source, target) {
  compressed <- tempfile()
  if (!file_test("-d", compressed)) dir.create(compressed, recursive = TRUE)

  remote_path <- file.path(source, "*")

  message(paste0("Retrieving packages from ", remote_path, " cache into ", compressed, "."))
  system(paste("gsutil", "-m", "cp", "-r", shQuote(remote_path), shQuote(compressed)))

  lapply(dir(compressed, full.names = TRUE, pattern = ".tar"), function(tar_file) {
    target_package <- strsplit(basename(tar_file), "\\.")[[1]][[1]]
    target_path <- file.path(target, target_package)

    if (!file_test("-d", target_path)) dir.create(target_path, recursive = TRUE)

    message(paste0("Restoring package from ", tar_file, " cache into ", target_path, "."))
    system2("tar", c("-xf", tar_file, "-C", target_path))
  })

  invisible(NULL)
}

retrieve_default_packages <- function() {
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
}

if (cache_enabled && use_packrat) {
  # line can be removed once packrat is on CRAN
  retrieve_cached_data(file.path(cache, "r"), .libPaths()[[1]])
}

cache_local <- if (use_packrat) tempfile() else .libPaths()[[1]]
cache_keras_local <- "~/.keras/"
cache_remote <- file.path(cache, ifelse(use_packrat, "packrat", "r"))
cache_keras_remote <- file.path(cache, "keras")

if (cache_enabled) {
  retrieve_cached_data(cache_remote, cache_local)
  retrieve_cached_data(cache_keras_remote, cache_keras_local)
}

if (use_packrat) {
  retrieve_packrat_packages(cache_local)
} else {
  retrieve_default_packages()
}

if (cache_enabled) {
  store_cached_data(cache_local, cache_remote, use_packrat)
  store_cached_data(cache_keras_local, cache_keras_remote)

  if (use_packrat) {
    # line can be removed once packrat is on CRAN
    store_cached_data(.libPaths()[[1]], file.path(cache, "r"))
  }
}

# Training ----

# read deployment information
deploy <- readRDS("cloudml/deploy.rds")

# source entrypoint
run_dir <- file.path("runs", deploy$id)
tfruns::training_run(file = deploy$entrypoint,
                     context = deploy$context,
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
  system(paste("gsutil", "cp", "-r", shQuote(source), shQuote(target)))
}
