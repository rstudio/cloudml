library(testthat)
library(cloudml)

if (identical(Sys.getenv("NOT_CRAN"), "true") && nchar(Sys.getenv("GCLOUD_ACCOUNT_FILE")) > 0) {
  test_check("cloudml")
}
