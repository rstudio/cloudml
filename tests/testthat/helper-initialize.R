
#' Read File from System Environment Variable
#'
#' To create an encoded account_file file use: \code{
#' gsub("\\n", "", jsonlite::base64_enc(serialize(readLines("keyfile.json"), NULL)))
#' }
#'
sysenv_file <- function(name, destination) {
  if (file.exists(destination))
    return()

  value_base64 <- Sys.getenv(name)

  if (nchar(value_base64) > 0) {
    file_contents <- unserialize(jsonlite::base64_dec(
      value_base64
    ))

    writeLines(file_contents, destination)
  }
}

cloudml_write_config <- function(destination = "gcloud.yml") {
  gcloud = list()

  if (nchar(Sys.getenv("GCLOUD_PROJECT")) > 0)
    gcloud$project <- Sys.getenv("GCLOUD_PROJECT")

  if (nchar(Sys.getenv("GCLOUD_ACCOUNT")) > 0)
    gcloud$account <- Sys.getenv("GCLOUD_ACCOUNT")

  if (nchar(Sys.getenv("GCLOUD_PROJECT")) > 0)
    options(
      "cloudml.storage" = paste("gs://", Sys.getenv("GCLOUD_PROJECT"), "/travis", sep = "")
    )

  yaml::write_yaml(gcloud, destination)
}

cloudml_tests_configured <- function() {
  nchar(Sys.getenv("GCLOUD_ACCOUNT_FILE")) > 0
}

if (cloudml_tests_configured()) {
  isTravis <- identical(Sys.getenv("TRAVIS"), "true")
  isAppVeyor <- identical(tolower(Sys.getenv("APPVEYOR")), "true")

  if (isTravis || isAppVeyor) {
    gcloud_install(update = FALSE)
  }

  if (isAppVeyor) {
    options(cloudml.snapshot.fallback.ok = TRUE)
  }

  options(repos = c(CRAN = "http://cran.rstudio.com"))

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
      ),
      echo = FALSE
    )
    message("Authenticated. Will run tests.")
  } else {
    message("Not authenticated. Won't run all tests.")
  }

  cloudml_write_config()
}
