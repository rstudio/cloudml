context("train")

expect_train_succeeds <- function(job) {
  expect_gt(nchar(job$id), 0)
  expect_gt(length(job$description), 0)
  expect_gt(nchar(job$description$state), 0)

  collected <- job_collect(job, view = "save")

  expect_true(dir.exists("runs"))

  job_dir <- dir("runs", full.names = TRUE)[[1]]
  expect_true(grepl("/cloudml", job_dir))

  tfruns_dir <- dir(job_dir, pattern = "tfruns", full.names = TRUE)
  expect_true(length(tfruns_dir) == 1)

  tfruns_props_dir <- dir(tfruns_dir, pattern = "properties", full.names = TRUE)
  expect_true(length(tfruns_props_dir) == 1)

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
  skip("plain tensorflow test is currently a subset of keras test")

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
