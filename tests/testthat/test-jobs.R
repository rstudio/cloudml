context("jobs")

test_that("job_list() succeeds", {
  all_jobs <- job_list()
  expect_gte(nrow(all_jobs), 0)
})
