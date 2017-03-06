library(tensorflow)
library(readr)

source("model.R")

config <- cloudml::config()

# read in the test data as an R data.frame
data <- read.table(
  config$eval_file,
  header = FALSE,
  sep = ",",
  stringsAsFactors = FALSE
)
names(data) <- CSV_COLUMNS

# use only first 5 rows of data
header <- head(data, n = 5)

# remove 'fnlwgt' column
header$fnlwgt <- NULL

# remove label
header[[LABEL_COLUMN]] <- NULL

# use local model directory
predictions <- cloudml::predict_local(config$job_dir, header)

# print predictions
cat(yaml::as.yaml(predictions))
