# required R packages
CRAN <- c("RCurl", "devtools", "readr")
GITHUB <- c(
  "tidyverse/purrr",
  "tidyverse/modelr",
  "rstudio/tensorflow",
  "rstudio/cloudml",
  "rstudio/keras",
  "rstudio/tfruns",
  "rstudio/tfestimators"
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
for (uri in GITHUB) {
  if (basename(uri) %in% installed)
    next
  devtools::install_github(uri)
}

# read deployment information
deploy <- readRDS("cloudml/deploy.rds")

# source entrypoint
tfruns::training_run(file = deploy$entrypoint,
                     context = deploy$environment,
                     flags = deploy$overlay,
                     echo = TRUE,
                     encoding = "UTF-8")
