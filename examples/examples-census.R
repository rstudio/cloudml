# copy census example to a separate directory (since it needs to download
# data files when running locally)
census_dir <- tempfile("cloudml_census_")
system(paste(
  "cp -R",
  shQuote(system.file("examples/census", package = "cloudml")),
  shQuote(census_dir)
))

# move to census directory
owd <- setwd(census_dir)
on.exit(setwd(owd))

# source the 'train.R' file (local workflow)
source("train.R")

# submit as local job with gcloud API
cloudml_local_train(census_dir)

# submit as remote job with gcloud API
cloudml_jobs_submit_training(census_dir)
