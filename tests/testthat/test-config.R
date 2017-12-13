context("config")

if (identical(Sys.getenv("TRAVIS"), "true")) {
  test_that("gcloud_config() can retrieve account and project from travis", {
    config <- gcloud_config()

    expect_true(!is.null(config$account))
    expect_true(!is.null(config$project))
  })
}
