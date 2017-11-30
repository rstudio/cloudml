context("train")

test_that("cloudml_train() can train and collect savedmodel", {
  if (!cloudml_tests_configured()) return()

  config_yml <- system.file("examples/mnist/cloudml.yml", package = "cloudml")
  file.copy("cloudml.yml", config_yml, overwrite = TRUE)

  job <- cloudml_train(
    application = system.file(
      "examples/mnist/",
      package = "cloudml"
    ),
    entrypoint = "train.R"
  )

  expect_gt(nchar(job$id), 0)
  expect_gt(length(job$description), 0)
  expect_gt(nchar(job$description$state), 0)

  collected <- job_collect(job)

  expect_true(dir.exists("runs"))

  saved_model <- dir(
    "runs",
    recursive = TRUE,
    full.names = TRUE,
    pattern = "saved_model")

  expect_gte(length(saved_model), 1)
})
