#' Submit a Job
#'
#' @template roxlate-application
#' @template roxlate-entrypoint
#' @template roxlate-arguments
#'
#' @export
cloudml_jobs_submit_training <- function(application = getwd(),
                                         job.name = random_string("gcloud-job-"),
                                         job.dir = job.name,
                                         runtime.version = "1.0",
                                         region = "us-central1",
                                         staging.bucket = staging_bucket(),
                                         arguments = list())
{
  # ensure application initialized
  initialize_application(application)
  owd <- setwd(dirname(application))
  on.exit(setwd(owd), add = TRUE)

  # generate setup script
  if (!file.exists("setup.py")) {
    file.copy(
      system.file("cloudml/setup.py", package = "cloudml"),
      "setup.py",
      overwrite = TRUE
    )
    setup.py <- normalizePath("setup.py")
    on.exit(unlink(setup.py), add = TRUE)
  }

  # generate deployment script
  args <-
    (Arguments()
     ("beta")
     ("ml")
     ("jobs")
     ("submit")
     ("training")
     (job.name)
     ("--package-path=%s", basename(application))
     ("--module-name=%s.deploy", basename(application))
     ("--job-dir=%s", job.dir)
     ("--region=%s", region)
     ("--runtime-version=%s", runtime.version)
     ("--"))

  if (length(arguments))
    for (argument in arguments)
      args(argument)

  system2(gcloud(), args())
}

cloudml_jobs_cancel <- "TODO"
cloudml_jobs_describe <- "TODO"
cloudml_jobs_list <- "TODO"
cloudml_jobs_logs <- "TODO"
