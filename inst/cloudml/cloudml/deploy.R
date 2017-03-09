# required R packages
CRAN <- c("RCurl", "devtools")
GITHUB <- c("rstudio/tensorflow", "rstudio/cloudml")

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

# extract command line arguments
arguments <- tensorflow::parse_arguments()
entrypoint  <- arguments[["cloudml_entrypoint"]]
config      <- arguments[["cloudml_config"]]
environment <- arguments[["cloudml_environment"]]

# apply config, environment
Sys.setenv(R_CONFIG_ACTIVE = config)
Sys.setenv(CLOUDML_EXECUTION_ENVIRONMENT = environment)

# read config overlay if available
if (file.exists("cloudml/overlay.rds")) {
  overlay <- readRDS("cloudml/overlay.rds")
  cloudml:::set_overlay(overlay)
}

# source a file 'requirements.R', if it exists
if (file.exists("requirements.R"))
  source("requirements.R")

# source entrypoint
source(entrypoint, echo = TRUE)
