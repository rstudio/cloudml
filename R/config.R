cloudml_config <- function(cloudml = NULL) {
  if (is.null(cloudml)) {
    file <- find_config_file(getwd(), "cloudml.yml")
    if (is.null(file)) {
      list()
    }
    else {
      yaml::read_yaml(file)
    }
  }
  else if (is.list(cloudml)) {
    cloudml
  }
  else if (is.character(cloudml)) {
    cloudml_ext <- tools::file_ext(cloudml)
    if (!cloudml_ext %in% c("json", "yml")) {
      maybe_cloudml <- file.path(cloudml, "cloudml.yml")
      if (file_test("-d", cloudml) && file.exists(maybe_cloudml)) {
        yaml::read_yaml(maybe_cloudml)
      }
      else {
        stop(
          "CloudML configuration file expected to have 'json' or 'yml' extension but '",
          cloudml_ext, "' found instead."
        )
      }
    }
    else {
      if (cloudml_ext == "json")
        jsonlite::read_json(cloudml)
      else
        yaml::read_yaml(cloudml)
    }
  }
  else {
    stop("CloduML configuration of class '", class(cloudml), "' is unsupported.")
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



