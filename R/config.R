cloudml_config <- function(path = getwd()) {

  file <- find_cloudml_config(path)
  if (is.null(file))
    return(list())

  config <- yaml::yaml.load_file(file)
  config$cloudml

}

find_cloudml_config <- function(path = getwd()) {
  tryCatch(
    rprojroot::find_root_file(
      "cloudml.yml",
      criterion = "cloudml.yml",
      path = path
    ),
    error = function(e) NULL
  )
}



