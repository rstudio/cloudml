
#' Read File from System Environment Variable
#'
#' To create an encoded file use: \code{gsub("\\n", "", jsonlite::base64_enc(serialize(readLines("tests/testthat/cloudml.yml"), NULL)))}
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

cloudml_write_config <- function(base = NULL) {
  config = list(
    gcloud = list(
      project = Sys.getenv("GCLOUD_ACCOUNT"),
      account = Sys.getenv("GCLOUD_PROJECT")
    ),
    cloudml = list(
      storage = paste("gs://", Sys.getenv("GCLOUD_ACCOUNT"), "/travis", sep = "")
    )
  )

  if (!is.null(base)) {
    base$gcloud$project <- config$gcloud$project
    base$gcloud$account <- config$gcloud$account
    base$cloudml$storage <- config$cloudml$storage
    config <- base
  }

  yaml::write_yaml(config, "cloudml.yml")
}

cloudml_tests_configured <- function() {
  nchar(Sys.getenv("GCLOUD_ACCOUNT_FILE")) > 0
}

if (cloudml_tests_configured()) {
  cloudml:::gcloud_install()

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
      )
    )
  }

  cloudml_write_config()
}
