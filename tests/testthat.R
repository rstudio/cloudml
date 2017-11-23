library(testthat)
library(cloudml)

if (identical(Sys.getenv("NOT_CRAN"), "true")) {
  test_check("cloudml")
}
