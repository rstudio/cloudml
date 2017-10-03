# A diagnostic script, for learning a bit about what's going on within
# a Cloud ML Engine instance.

newline <- function() {
  cat("", sep = "\n")
}

printf <- function(...) {
  cat(sprintf(...), sep = "\n")
}

printf("[command-line arguments]")
print(commandArgs(TRUE))
newline()

printf("[session info]")
print(utils::sessionInfo())
newline()

printf("[working directory]")
printf(getwd())
newline()

printf("[environment variables]")
str(as.list(Sys.getenv()))
newline()

if (nzchar(Sys.which("tree"))) {
  printf("[tree]")
  try(system("tree"), silent = TRUE)
  newline()
}

if (nzchar(Sys.which("python"))) {
  printf("[python]")
  try(system("python --version"), silent = TRUE)
  newline()
}
