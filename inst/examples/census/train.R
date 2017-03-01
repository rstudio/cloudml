library(tensorflow)

source("modules/model.R")

# Define some aliases for commonly-used modules
learn                    <- tf$contrib$learn
metrics                  <- tf$contrib$metrics
learn_runner             <- learn$python$learn$learn_runner
saved_model_export_utils <- learn$python$learn$utils$saved_model_export_utils

# Read application config
config <- config::get("train")

# Download data for local configurations if not available
active_config <- Sys.getenv("R_CONFIG_ACTIVE", unset = "default")
if (active_config %in% c("default", "local")) {
  gsutil <- cloudml::gsutil()

  if (!file.exists(config$train_file)) {
    dir.create(dirname(config$train_file), recursive = TRUE, showWarnings = FALSE)
    system(paste(gsutil, "cp gs://tf-ml-workshop/widendeep/adult.data", config$train_file))
  }

  if (!file.exists(config$eval_file)) {
    dir.create(dirname(config$eval_file), recursive = TRUE, showWarnings = FALSE)
    system(paste(gsutil, "cp gs://tf-ml-workshop/widendeep/adult.test", config$eval_file))
  }
}

# Define experiment function
experiment_fn <- function(output_dir) {

  train_input <- generate_input_fn(
    filename   = config$train_file,
    num_epochs = config$train_num_epochs,
    batch_size = config$train_batch_size
  )

  eval_input <- generate_input_fn(
    filename   = config$eval_file,
    num_epochs = config$eval_num_epochs,
    batch_size = config$eval_batch_size
  )

  learn$Experiment(

    build_estimator(
      model_dir      = config$job_dir,
      embedding_size = config$estimator_embedding_size,
      hidden_units   = config$estimator_hidden_units
    ),

    train_input_fn = train_input,

    eval_input_fn = eval_input,

    eval_metrics = list(
      "training/hptuning/metric" = learn$MetricSpec(
        metric_fn = metrics$streaming_accuracy,
        prediction_key = "logits"
      )
    ),

    export_strategies = list(
      saved_model_export_utils$make_export_strategy(
        serving_input_fn,
        default_output_alternative_key = NULL,
        exports_to_keep = 1L
      )
    )
  )
}

# Run the training job.
learn_runner$run(experiment_fn, config$job_dir)
