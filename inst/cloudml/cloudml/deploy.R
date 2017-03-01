# extract entrypoint
arguments <- commandArgs(trailingOnly = TRUE)
entrypoint <- arguments[[1]]

# read config overlay if available
config <- list()
if (file.exists("cloudml/config.rds"))
  config <- readRDS("cloudml/config.rds")

# generate filter to overlay this with config
filter <- cloudml:::config_filter(config)
config::add_filter(filter)

# source entrypoint
source(entrypoint)
