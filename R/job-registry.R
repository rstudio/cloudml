job_registry <- function() {
  .globals$job_registry
}

register_job <- function(job, registry = job_registry()) {
  registry[[job$job_name]] <- job
}

resolve_job <- function(id) {
  registry <- job_registry()

  # if we have an associated job object in the registry, use that
  if (exists(id, envir = registry))
    return(registry[[id]])

  # otherwise, construct it by querying Google Cloud
  arguments <- (MLArgumentsBuilder()
                ("jobs")
                ("describe")
                (id))

  output <- gexec(gcloud(), arguments(), stdout = TRUE)
  desc <- yaml::yaml.load(paste(output, collapse = "\n"))

  # if we have a 'trainingInput' field, this was a training
  # job (as opposed to a prediction job)
  # TODO: handle predict jobs
  class <- if ("trainingInput" %in% names(desc))
    "train"
  else
    "predict"

  job <- cloudml_job(
    class    = class,
    job_name = id,
    job_dir  = desc$trainingInput$jobDir
  )

  # store in registry
  registry[[id]] <- job

  job
}
