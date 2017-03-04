# install required R packages
options(repos = c(CRAN = "http://cran.rstudio.com"))
if (.Platform$OS.type == "unix" && Sys.info()['sysname'] != "Darwin")
  options(download.file.method = "wget")
install.packages(c("devtools", "RCurl"))
devtools::install_github("rstudio/tensorflow")
devtools::install_github("rstudio/cloudml")

# extract command line arguments and populate R environment as required
arguments <- as.list(commandArgs(trailingOnly = TRUE))
entrypoint <- arguments[[1]]
config     <- arguments[[2]]
Sys.setenv(R_CONFIG_ACTIVE = config)
environment <- strsplit(arguments[[3]], "=")[[1]][[2]]
Sys.setenv(CLOUDML_EXECUTION_ENVIRONMENT = environment)

# read config overlay if available
overlay <- list()
if (file.exists("cloudml/config.rds"))
  overlay <- readRDS("cloudml/config.rds")

# install filter to overlay this into config
uuid <- config::add_filter(cloudml:::config_filter(overlay))

# source entrypoint
source(entrypoint)
