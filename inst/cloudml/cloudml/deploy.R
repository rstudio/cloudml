
# required R packages
CRAN <- c(
  "Rcpp",
  "yaml"
)

GITHUB <- c(
  "rstudio/config",
  "rstudio/reticulate",
  "rstudio/tensorflow",
  "rstudio/cloudml"
)

# save repository + download methods
repos <- getOption("repos")
download.file.method <- getOption("download.file.method")
download.file.extra  <- getOption("download.file.extra")

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

  cloudml:::install_github(uri)
}

# extract command line arguments
arguments <- tensorflow::parse_arguments()
entrypoint  <- arguments[["cloudml_entrypoint"]]
config      <- arguments[["cloudml_config"]]
environment <- arguments[["cloudml_environment"]]

# apply config, environment
Sys.setenv(R_CONFIG_ACTIVE = config)
Sys.setenv(CLOUDML_EXECUTION_ENVIRONMENT = environment)

# read config overlay if available
overlay <- list()
if (file.exists("cloudml/overlay.rds"))
  overlay <- readRDS("cloudml/overlay.rds")

# merge in command line arguments (these can be provided
# during e.g. hyperparameter tuning)
overlay <- config::merge(overlay, arguments)

# set the active overlay
cloudml:::set_overlay(overlay)

# source entrypoint
source(entrypoint, echo = TRUE)
