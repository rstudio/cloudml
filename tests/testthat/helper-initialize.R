
gcloud_account_file <- function() {
  #
  # Sys.setenv(GCLOUD_ACCOUNT_FILE = gsub("\\n", "", jsonlite::base64_enc(
  #   serialize(readLines("<key.json>"), NULL)))
  # ))
  #
  account_file <- NULL
  account_base64 <- Sys.getenv("GCLOUD_ACCOUNT_FILE")

  if (nchar(account_base64) > 0) {
    account_contents <- unserialize(jsonlite::base64_dec(
      account_base64
    ))

    account_file <- tempfile(fileext = ".json")
    jsonlite::write_json(account_contents, account_file)
  }

  account_file
}

cloudml:::gcloud_install()
account_file <- gcloud_account_file()

if (!is.null(account_file)) {
  gcloud_exec(
    "auth",
    "activate-service-account",
    paste(
      "--key-file",
      account_file,
      sep = "="
    )
  )
}
