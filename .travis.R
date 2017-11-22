parent_dir <- dir("../", full.names = TRUE)
package <- parent_dir[grepl("cloudml_", parent_dir)]
install.packages(package, repos = NULL, type = "source")

source("testthat.R")
