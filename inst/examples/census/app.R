# TODO: This is a hack to ensure that TensorFlow v1.0.0 is installed,
# rather than TensorFlow v0.11.0rc2.
system("pip install --upgrade tensorflow")

library(tensorflow)

printf <- function(...) cat(sprintf(...), sep = "\n")

printf("")
printf("---")
printf("Using R 'tensorflow' package version: %s", packageVersion("tensorflow"))
printf("Using TensorFlow version:             %s", tf$`__version__`)
printf("R Version:                            %s", getRversion())
printf("---")
printf("")

source("modules/model.R")

argparse <- import("argparse")
json     <- import("json")
os       <- import("os")

# Define some aliases for commonly-used modules
learn                    <- tf$contrib$learn
metrics                  <- tf$contrib$metrics
learn_runner             <- learn$python$learn$learn_runner
saved_model_export_utils <- learn$python$learn$utils$saved_model_export_utils

generate_experiment_fn <- function(train_file,
                                   eval_file,
                                   num_epochs = NULL,
                                   train_batch_size = 40L,
                                   eval_batch_size = 40L,
                                   embedding_size = 8L,
                                   hidden_units = NULL,
                                   checkpoint_dir = NULL,
                                   ...)
{
  experiment_fn <- function(output_dir) {

    train_input <- generate_input_fn(
      train_file,
      num_epochs = num_epochs,
      batch_size = train_batch_size
    )

    eval_input <- generate_input_fn(
      eval_file,
      batch_size = eval_batch_size
    )

    learn$Experiment(

      build_estimator(
        checkpoint_dir,
        embedding_size = embedding_size,
        hidden_units = hidden_units
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
      ),
      ...
    )
  }

  experiment_fn
}

parser <- argparse$ArgumentParser()

invisible({

  parser$add_argument(
    "--train-file",
    help = "GCS or local path to training data.",
    required = TRUE
  )

  parser$add_argument(
    "--num-epochs",
    help = "Maximum number of training data epochs on which to train.",
    default = 10L,
    type = function(x) as.integer(x)
  )

  parser$add_argument(
    "--train-batch-size",
    help = "Batch size for training steps.",
    default = 40L,
    type = function(x) as.integer(x)
  )

  parser$add_argument(
    "--eval-batch-size",
    help = "Batch size for evaluation steps.",
    default = 40L,
    type = function(x) as.integer(x)
  )

  parser$add_argument(
    "--train-steps",
    help = "Steps to run the training job for.",
    default = 10L,
    type = function(x) as.integer(x)
  )

  parser$add_argument(
    "--eval-steps",
    help = "Number of steps to run evaluation for at each checkpoint.",
    default = 100L,
    type = function(x) as.integer(x)
  )

  parser$add_argument(
    "--eval-file",
    help = "GCS or local path to evaluation data.",
    required = TRUE
  )

  parser$add_argument(
    "--embedding-size",
    help = "Number of embedding dimensions for categorical columns.",
    default = 8L,
    type = function(x) as.integer(x)
  )

  parser$add_argument(
    "--hidden-units",
    help = "List of hidden layer sizes to use for DNN feature columns.",
    default = list(100L, 70L, 50L, 25L),
    type = function(x) as.integer(x)
  )

  parser$add_argument(
    "--checkpoint-dir",
    help = "GCS location to write checkpoints and export models.",
    required = TRUE
  )

  parser$add_argument(
    "--eval-delay-secs",
    help = "How long to wait before running first evaluation.",
    default = 10L,
    type = function(x) as.integer(x)
  )

  parser$add_argument(
    "--min-eval-frequency",
    help = "Minimum number of training steps between evaluations.",
    default = 1L,
    type = function(x) as.integer(x)
  )

})

args <- parser$parse_args(commandArgs(TRUE))
arguments <- args$`__dict__`

# Run the training job.
checkpoint_dir <- arguments$checkpoint_dir
experiment_fn <- do.call(generate_experiment_fn, arguments)
learn_runner$run(experiment_fn, checkpoint_dir)
