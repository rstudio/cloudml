
#' Read File from System Environment Variable
#'
#' To create an encoded file use: \code{jsonlite::base64_enc(serialize(readLines("<key.json>"), NULL))}
#'
sysenv_file <- function(name, destination) {
  value_base64 <- Sys.getenv(name)

  if (nchar(value_base64) > 0) {
    file_contents <- unserialize(jsonlite::base64_dec(
      value_base64
    ))

    writeLines(file_contents, destination)
  }
}

cloudml:::gcloud_install()

account_file <- tempfile(fileext = ".json")
sysenv_file("GCLOUD_ACCOUNT_FILE", account_file)

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

sysenv_file("GCLOUD_CONFIGT_FILE", "cloudml.yml")
