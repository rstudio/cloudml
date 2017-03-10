

docs_site <- function (input, encoding = getOption("encoding"), ...) {
  source("docs.R", local = TRUE)
  docs_site_impl(input, encoding, ...)
}

