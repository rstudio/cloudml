install_github <- function(repo, ...) {

  # delegate to devtools if available
  if ("devtools" %in% loadedNamespaces())
    return(devtools::install_github(repo, ...))

  # otherwise, manually construct an API link ourselves
  owd <- setwd(tempdir())
  on.exit(setwd(owd), add = TRUE)
  lapply(repo, function(path) {

    # construct path toe github API endpoint
    fmt <- "https://api.github.com/repos/%s/tarball/master"
    url <- sprintf(fmt, repo)

    # download to temporary directory
    destfile <- tempfile()
    download.file(url, destfile = destfile)

    # extract tarball
    pkgdir <- tempfile()
    untar(destfile, exdir = pkgdir)

    # attempt to install
    setwd(pkgdir)
    pkgpath <- list.files(pkgdir)[[1]]
    system(paste("R CMD INSTALL", pkgpath))
  })
}
