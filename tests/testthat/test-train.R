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

with_temp_training_dir <- function(training_dir, expr) {

  # create temp directory and copy training_dir to it
  temp_training_dir <- tempfile("training-dir", fileext = ".dir")
  dir.create(temp_training_dir)
  on.exit(unlink(temp_training_dir, recursive = TRUE), add = TRUE)
  file.copy(training_dir, temp_training_dir, recursive = TRUE)
  withr::with_dir(file.path(temp_training_dir, basename(training_dir)), expr)
}

test_that("cloudml_train() can train and collect savedmodel", {
  with_temp_training_dir(system.file("examples/mnist", package = "cloudml"), {
    cloudml_write_config()
    job <- cloudml_train()
    expect_train_succeeds(job)
  })
})

test_that("cloudml_train() can train keras model", {
  with_temp_training_dir(system.file("examples/keras", package = "cloudml"), {
    cloudml_write_config()
    job <- cloudml_train()
    expect_train_succeeds(job)
  })

})
