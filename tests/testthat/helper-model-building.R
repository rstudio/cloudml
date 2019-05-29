
fnames <- list.files("model-building/")

models <- gsub(".R$", "", fnames)

get_version <- function(model) {
  stringr::str_extract(model, "[0-9].*$")
}

if  (!file.exists("data/mnist.rds"))
  source("data/get-mnist.R")

for (model in models) {

  if (dir.exists(paste0("models/", model)))
    next

  tf_version <- get_version(model)
  envname <- paste0("tf-", tf_version)

  if (!envname %in% reticulate::virtualenv_list())
    tensorflow::install_tensorflow(version = tf_version, envname = envname,
                                   restart_session = FALSE)

  message("Running ", model)

  p <- processx::process$new(
    command = "Rscript",
    args = paste0("model-building/", model, ".R"), stderr = "|", stdout = "|",
    wd = getwd()
    )

  while(p$is_alive()) Sys.sleep(1)

}






