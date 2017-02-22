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
                                         region = "us-central1",
                                         staging.bucket = staging_bucket(),
                                         arguments = list())
{
  application <- normalizePath(application)
  deployment_dir <- generate_deployment_dir(application)

  owd <- setwd(deployment_dir)
  on.exit(setwd(owd), add = TRUE)

  args <-
    (Arguments()
     ("beta")
     ("ml")
     ("jobs")
     ("submit")
     ("training")
     (job.name)
     ("--package-path %s", basename(application))
     ("--module-name %s.deploy", basename(application))
     ("--job-dir %s", job.dir)
     ("--region %s", region)
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
