cloudml_config <- function(path = getwd()) {

  file <- rprojroot::find_root_file(
    "cloudml.yml",
    criterion = "cloudml.yml",
    path = path
  )

  config <- yaml::yaml.load_file(file)
  config$cloudml

}
