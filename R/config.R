cloudml_config <- function(path = getwd()) {

  file <- find_config_file(path, "cloudml.yml")
  if (is.null(file)) {
    file <- find_config_file(path, "cloudml.json")
    if (is.null(file)) {
      return(list())
    }
    else {
      jsonlite::read_json(file)
    }
  }
  else {
    yaml::yaml.load_file(file)
  }
}

find_config_file <- function(path = getwd(), name) {
  tryCatch(
    rprojroot::find_root_file(
      name,
      criterion = name,
      path = path
    ),
    error = function(e) NULL
  )
}



