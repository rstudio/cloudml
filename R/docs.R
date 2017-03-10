

docs_site <- function (input, encoding = getOption("encoding"), ...) {
  docs_site_impl <- function(...) {}
  source("doc-utils.R", local = TRUE)
  docs_site_impl(input, encoding, ...)
}

