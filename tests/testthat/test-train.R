context("train")

expect_train_succeeds <- function(job) {
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
}

test_that("cloudml_train() can train and collect savedmodel", {
  if (!cloudml_tests_configured()) return()

  mnist_config <- yaml::yaml.load(readLines(system.file("examples/mnist/cloudml.yml", package = "cloudml")))
  cloudml_write_config(mnist_config)

  job <- cloudml_train(
    application = system.file(
      "examples/mnist/",
      package = "cloudml"
    ),
    entrypoint = "train.R"
  )

  expect_train_succeeds(job)
})

test_that("cloudml_train() can train keras model", {
  if (!cloudml_tests_configured()) return()

  keras_config <- yaml::yaml.load(readLines(system.file("examples/keras/cloudml.yml", package = "cloudml")))
  cloudml_write_config(keras_config)

  job <- cloudml_train(
    application = system.file(
      "examples/keras/",
      package = "cloudml"
    ),
    entrypoint = "train.R"
  )

  expect_train_succeeds(job)
})
