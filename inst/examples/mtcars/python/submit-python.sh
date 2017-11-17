~/google-cloud-sdk/bin/gcloud ml-engine jobs submit training "mtcars_py8" --job-dir gs://rstudio-cloudml/mtcars --package-path mtcars --module-name mtcars.train --region us-central1
