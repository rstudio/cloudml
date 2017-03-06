
# extract command line arguments
arguments <- tensorflow::parse_arguments()
entrypoint  <- arguments[["cloudml_entrypoint"]]
config      <- arguments[["cloudml_config"]]
environment <- arguments[["cloudml_environment"]]

# apply config, environment
Sys.setenv(R_CONFIG_ACTIVE = config)
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
if (file.exists("cloudml/config.rds"))
  overlay <- readRDS("cloudml/config.rds")

# set extra config
cloudml:::set_extra_config(overlay)

# source entrypoint
source(entrypoint, echo = TRUE)
