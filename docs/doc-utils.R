

ref <- function(name, desc = NULL, table = !is.null(desc)) {
  # | [`func`](reference/func.html) | My func |
  table <- ifelse(table, "| ", "")
  desc <- paste(desc, table)
  knitr::asis_output(
    paste0(table, '[`', name, '`](reference/', name, '.html)', table, desc, '\n') 
  )
}


docs_site_impl <- function (input, encoding = getOption("encoding"), ...) {

  # get the default site from rmarkdown
  site <- rmarkdown:::default_site(input, encoding, ...)

  # get the default site render function
  render <- site$render

  # monker patch render to call pkgdown::build_site as well
  site$render <- function(...) {

    # use pkgdown to render reference
    with_options(c(repos = "https://cran.rstudio.com"), {
      pkgdown::build_site(dirname(normalizePath(input)), preview = FALSE)
    })

    # delegate
    render(...)
  }

  # return site
  site
}

