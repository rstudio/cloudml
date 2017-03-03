# install required R packages
options(repos = c(CRAN = "http://cran.rstudio.com"))
if (.Platform$OS.type == "unix" && Sys.info()['sysname'] != "Darwin")
  options(download.file.method = "wget")
install.packages(c("devtools", "RCurl"))
devtools::install_github("rstudio/tensorflow")
devtools::install_github("rstudio/cloudml")

# extract command line arguments
arguments <- as.list(commandArgs(trailingOnly = TRUE))
entrypoint <- arguments[[1]]
config     <- arguments[[2]]

# set up environment
Sys.setenv(
  GCLOUD_EXECUTION_ENVIRONMENT = "1",
  R_CONFIG_ACTIVE              = config
)

# read config overlay if available
overlay <- list()
if (file.exists("cloudml/config.rds"))
  overlay <- readRDS("cloudml/config.rds")

# generate filter to overlay this with config
# TODO: receive from 'cloudml' package once it's public
filter <- function(config) {

  # TODO: parsing of command line arguments

  # merge config with overlay
  config <- config::merge(config, overlay)

  # TODO: resolve gs:// URLs

  # set defaults for missing parameters
  config[["job_dir"]] <- config[["job_dir"]] %||% "jobs"

  # return the filtered config
  config
}

uuid <- config::add_filter(filter)

# source entrypoint
source(entrypoint)
