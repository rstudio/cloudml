# required R packages
CRAN <- c("RCurl", "devtools", "readr")
GITHUB <- c(
  list(uri = "tidyverse/purrr",      ref = NULL),
  list(uri = "tidyverse/modelr",     ref = NULL),
  list(uri = "rstudio/tensorflow",   ref = NULL),
  list(uri = "rstudio/cloudml",      ref = "feature/sdk"),
  list(uri = "rstudio/keras",        ref = NULL),
  list(uri = "rstudio/tfruns",       ref = NULL),
  list(uri = "rstudio/tfestimators", ref = NULL)
)

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

# attempt to restore using a packrat lockfile
if (file.exists("packrat/packrat.lock")) {

  # ensure packrat is installed
  if (!"packrat" %in% rownames(installed.packages()))
    install.packages("packrat")

  # attempt a project restore
  packrat::restore()
  packrat::on()
}

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

# Training ----

library(cloudml)

# read deployment information
deploy <- readRDS("cloudml/deploy.rds")

# source entrypoint
run_dir <- tfruns::unique_run_dir()
tfruns::training_run(file = deploy$entrypoint,
                     context = deploy$environment,
                     flags = deploy$overlay,
                     encoding = "UTF-8",
                     echo = TRUE,
                     view = FALSE,
                     run_dir = run_dir)

# upload run directory to requested bucket (if any)
config <- yaml::yaml.load_file("cloudml.yml")
cloudml <- config$cloudml
storage <- cloudml[["storage-bucket"]]
if (is.character(storage)) {
  source <- run_dir
  target <- file.path(storage, run_dir)
  system(paste(gsutil_path(), "cp", "-r", shQuote(source), shQuote(target)))
}
