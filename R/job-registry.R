job_registry <- function() {
  .__JOB_REGISTRY__.
}

register_job <- function(job, registry = job_registry()) {
  registry[[job$id]] <- job
}

resolve_job <- function(id, registry = job_registry()) {

  # if we have an associated job object in the registry, use that
  if (exists(id, envir = registry))
    return(registry[[id]])

  # otherwise, construct it by querying Google Cloud
  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("describe")
                (id))

  output <- gexec(gcloud(), arguments(), stdout = TRUE, stderr = FALSE)
  description <- yaml::yaml.load(paste(output, collapse = "\n"))

  # if we have a 'trainingInput' field, this was a training
  # job (as opposed to a prediction job)
  # TODO: handle predict jobs
  class <- if ("trainingInput" %in% names(description))
    "train"
  else
    "predict"

  job <- cloudml_job(class, id, description)

  # store in registry
  registry[[id]] <- job

  job
}
