context("jobs")

test_that("job_list() succeeds", {
  if (!cloudml_tests_configured()) return()

  all_jobs <- job_list()
  expect_gte(nrow(all_jobs), 0)
})
