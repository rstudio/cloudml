library(cloudml)

# Download data if not available.
cloudml:::ensure_directory("internal/data")
if (!file.exists("internal/data/adult.data")) {
  gsutil <- cloudml:::gsutil()
  system(paste(gsutil, "cp gs://tf-ml-workshop/widendeep/* internal/data/"))
}

# Generate paths to internal data.
train_file <- normalizePath("internal/data/adult.data")
eval_file  <- normalizePath("internal/data/adult.test")
job_dir <- tempfile("checkpoint-")
cloudml:::ensure_directory(job_dir)

# Train locally.
cloudml_local_train(
  application = "inst/examples/census",
  arguments = list(
    sprintf("--train-file=%s", train_file),
    sprintf("--eval-file=%s", eval_file),
    sprintf("--train-steps=1000"),
    sprintf("--job_dir=%s", job_dir)
  )
)

# Train remotely.
date <- format(Sys.Date(), "%Y%m%d_")
prefix <- paste("rstudio_cloudml_job", date, sep = "_")
job_name <- basename(tempfile(prefix))

job_dir <- file.path("gs://rstudio-cloudml-demo-ml/census/jobs", job_name)
train_file     <-    "gs://rstudio-cloudml-demo-ml/census/data/adult.data"
eval_file      <-    "gs://rstudio-cloudml-demo-ml/census/data/adult.test"
staging_bucket <-    "gs://rstudio-cloudml-demo-ml/census/staging"

cloudml_jobs_submit_training(
  job.name = job_name,
  job.dir = job_dir,
  staging.bucket = staging_bucket,
  application = "inst/examples/census",
  arguments = list(
    sprintf("--train-file=%s", train_file),
    sprintf("--eval-file=%s", eval_file),
    sprintf("--train-steps=1000")
  )
)
