
gcloud_account_file <- function() {
  account_keys <- c(
    "GCLOUD_PROJECT_ID",
    "GCLOUD_PRIVATE_KEY_ID",
    "GCLOUD_PRIVATE_KEY",
    "GCLOUD_CLIENT_EMAIL",
    "GCLOUD_CLIENT_ID"
  )

  account_path <- dir(getwd(), recursive = TRUE, pattern = "account.json", full.names = TRUE)
  account_data <- jsonlite::read_json(account_path)

  account_secrets <- lapply(account_data, function(e) {
    jsonlite::unbox(if (e %in% account_keys) Sys.getenv(e) else e)
  })

  account_file <- tempfile(fileext = ".json")
  jsonlite::write_json(account_secrets, account_file)

  account_file
}

cloudml:::gcloud_install()
account_file <- gcloud_account_file()

gcloud_exec(
  "auth",
  "activate-service-account",
  paste(
    "--key-file",
    account_file,
    sep = "="
  )
)
