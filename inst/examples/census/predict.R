library(tensorflow)

source("model.R")

# read in the test data as an R data.frame
data <- read.table(
  cloudml::gs_data("gs://rstudio-cloudml-demo-ml/census/data/local.adult.test"),
  col.names = CSV_COLUMNS,
  header = FALSE,
  sep = ",",
  stringsAsFactors = FALSE,
  nrows = 5
)

# remove some columns
header$fnlwgt <- NULL
header[[LABEL_COLUMN]] <- NULL

# generate predictions
predictions <- cloudml::predict_local("jobs/local", header)

# print predictions
cat(yaml::as.yaml(predictions))
