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
config <- list()
if (file.exists("cloudml/config.rds"))
  config <- readRDS("cloudml/config.rds")

# generate filter to overlay this with config
filter <- cloudml:::config_filter(config)
uuid <- config::add_filter(filter)

# source entrypoint
source(entrypoint)
