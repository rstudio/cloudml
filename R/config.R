

# filter passed to config::add_filter to inject additional configuration
# into calls to config::get and to resolve gs:// urls to local paths
# when not running on gcloud
config_filter <- function(extra_config) {

  force(extra_config)

  function(config) {

    # add any command line values passed to the R script into the extra_config
    # (this is used when CloudML passes arguments during hyperparameter turning)
    #
    # TODO: forward these args in deploy.py and pick out args after --
    #
    cmd_args <- commandArgs(trailingOnly = TRUE)

    # merge the extra config with the provided config
    config <- config::merge(config, extra_config)

    # provide defaults
    config[["job_dir"]] <- config[["job_dir"]] %||% "jobs"

    # return the filtered config
    config
  }
}

