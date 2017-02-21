#' Train a Model Locally
#'
#' @template roxlate-application
#' @template roxlate-entrypoint
#' @template roxlate-arguments
#'
#' @export
cloudml_local_train <- function(application = getwd(),
                                entrypoint = file.path(application, "app.R"),
                                arguments = list())
{
  application <- normalizePath(application)
  entrypoint  <- normalizePath(entrypoint)

  # Move to application directory
  owd <- setwd(application)
  on.exit(setwd(owd), add = TRUE)

  # Populate gcloud deployment directory.
  ensure_directory("cloudml")
  ensure_file("cloudml/__init__.py")
  file.copy(
    system.file("python/deploy.py", package = "cloudml"),
    "cloudml/deploy.py",
    overwrite = TRUE
  )

  # Add gcloud-specific arguments
  args <-
    (Arguments()
     ("beta")
     ("ml")
     ("local")
     ("train")
     ("--package-path cloudml")
     ("--module-name cloudml.deploy")
     ("--"))

  # Add task arguments (if applicable)
  if (length(arguments))
    for (argument in arguments)
      args(argument)

  arguments <- args()
  system2(gcloud(), arguments)
}
