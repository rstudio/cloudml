gcloud_config <- function(path = getwd()) {

  file <- rprojroot::find_root_file(
    "cloudml.yml",
    criterion = "cloudml.yml",
    path = path
  )

  config <- yaml::yaml.load_file(file)

  # validate required 'gcloud' fields
  gcloud <- config$gcloud
  for (field in c("project", "account")) {

    if (is.null(gcloud[[field]])) {
      fmt <- "[%s]: field '%s' is missing"
      stopf(fmt, as_aliased_path(file), field)
    }

    if (!is.character(gcloud[[field]])) {
      fmt <- "[%s]: field '%s' is not a string"
      stopf(fmt, as_aliased_path(file), field)
    }

  }

  gcloud
}

#' Google Cloud Account
#'
#' Gets/Sets the Google Cloud account through the Google Cloud SDK.
#'
#' @param account The account to use in subsequent Google Cloud SDK operations.
#'   Usually the email associated to the account.
#'
#' @return The account associated to the Google Cloud SDK.
#'
#' @export
gcloud_account <- function(account = NULL) {
  if (!is.null(account)) gcloud_exec("config", "set", "core/account", account)
  gcloud_exec("config", "get-value", "core/account")
}

#' Google Cloud Project
#'
#' Gets/Sets the Google Cloud account through the Google Cloud SDK.
#'
#' @param project The project to use in subsequent Google Cloud SDK operations.
#'
#' @return The project associated to the Google Cloud SDK.
#'
#' @export
gcloud_project <- function(account, project) {
  if (!is.null(project)) gcloud_exec("config", "set", "core/project", project)
  gcloud_exec("config", "set", "core/project", project)
}
