job_registry <- function() {
  .__JOB_REGISTRY__.
}

register_job <- function(job, registry = job_registry()) {
  registry[[job$id]] <- job
}

resolve_job <- function(id, registry = job_registry()) {
  gcloud <- gcloud_config()

  # resolve "latest" to latest job
  if (identical(id, "latest"))
    id <- job_list()[[1,"JOB_ID"]]

  # if we have an associated job object in the registry, use that
  if (exists(id, envir = registry))
    return(registry[[id]])

  # otherwise, construct it by querying Google Cloud
  arguments <- (MLArgumentsBuilder(gcloud)
                ("jobs")
                ("describe")
                (id))

  output <- gcloud_exec(args = arguments())
  description <- yaml::yaml.load(paste(output$stdout, collapse = "\n"))

  # if we have a 'trainingInput' field, this was a training
  # job (as opposed to a prediction job)
  class <- if ("trainingInput" %in% names(description))
    "train"
  else
    "predict"

  job <- cloudml_job(class, id, description)

  # store in registry
  registry[[id]] <- job

  job
}
