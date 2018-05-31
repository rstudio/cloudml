context("version")

test_that("python version being tested is correct", {
  python_version <- Sys.getenv("PYTHON_VERSION")
  sys <- reticulate::import("sys")

  if (nchar(python_version) > 0) {
    testthat::expect_equal(sys$version_info$major, as.integer(python_version))
  }
})
