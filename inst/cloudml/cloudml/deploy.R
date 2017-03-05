
# extract command line arguments and populate R environment as required
arguments <- as.list(commandArgs(trailingOnly = TRUE))
entrypoint <- arguments[[1]]
config     <- arguments[[2]]
Sys.setenv(R_CONFIG_ACTIVE = config)
environment <- strsplit(arguments[[3]], "=")[[1]][[2]]
Sys.setenv(CLOUDML_EXECUTION_ENVIRONMENT = environment)

# install required R packages if we in gcloud
if (identical(environment, "gcloud")) {
  options(repos = c(CRAN = "http://cran.rstudio.com"))
  if (.Platform$OS.type == "unix" && Sys.info()['sysname'] != "Darwin")
    options(download.file.method = "wget")
  install.packages(c("devtools", "RCurl"))
  devtools::install_github("rstudio/tensorflow")
  devtools::install_github("rstudio/cloudml")
}

# read config overlay if available
overlay <- list()
if (file.exists("cloudml/config.rds")) {
  overlay <- readRDS("cloudml/config.rds")
  unlink("cloudml/config.rds")
}

# set extra config
cloudml:::set_extra_config(overlay)

# source entrypoint
source(entrypoint, echo = TRUE)
