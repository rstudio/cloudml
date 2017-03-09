# given a environment 'target' and a list of lists 'sources',
# provide a function that populates 'target' based on the
# first discovered entry in the list of 'sources', or fall
# back to the default
make_config_populator <- function(target, sources) {

  # force promises
  force(target)
  force(sources)

  # helper for resolving functions against current state
  resolve <- function(default) {
    if (is.function(default))
      default(target)
    else
      default
  }

  function(...) {

    dots <- list(...)
    enumerate(dots, function(name, default) {

      # attempt to resolve 'name' in config
      for (source in sources) {
        if (!is.null(source[[name]])) {
          target[[name]] <<- source[[name]]
          return(TRUE)
        }
      }

      # no config provides this value; use the default
      resolved <- resolve(default)
      if (!is.null(resolved)) {
        target[[name]] <<- resolved
        return(TRUE)
      }

      # nothing provided
      FALSE

    })

  }
}

resolve_config <- function(config) {
  if (is.list(config))
    config
  else
    config::get(config = config)
}

resolve_train_overlay <- function(application,
                                  dots,
                                  config)
{
  conf <- resolve_config(config)

  # prepare our overlay + helper for filling in fields
  overlay <- new.env(parent = emptyenv())
  populate <- make_config_populator(overlay, list(dots, conf))

  populate(
    entrypoint      = "train.R",
    job_output      = "jobs/local",
    job_name        = unique_job_name(application, attr(conf, "config")),
    job_dir         = function(.) file.path(.$job_output, .$job_name),
    staging_bucket  = NULL,
    region          = "us-central1",
    runtime_version = "1.0"
  )

  as.list(overlay)
}
