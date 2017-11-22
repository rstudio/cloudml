~/google-cloud-sdk/bin/gcloud ml-engine jobs submit training "mtcars_py" --job-dir gs://rstudio-cloudml/mtcars --package-path source --module-name source.train --region us-central1
