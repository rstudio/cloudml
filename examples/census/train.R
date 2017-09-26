library(tensorflow)

source("model.R")

# define some aliases for commonly-used modules
learn                    <- tf$contrib$learn
metrics                  <- tf$contrib$metrics
learn_runner             <- learn$python$learn$learn_runner
saved_model_export_utils <- learn$python$learn$utils$saved_model_export_utils

# read application config and resolve data files
FLAGS <- flags(

  flag_string("job_dir", tfruns::run_dir()),
  flag_string("train_file", "gs://cloudml-public/census/data/adult.data.csv"),
  flag_string("eval_file", "gs://cloudml-public/census/data/adult.test.csv"),

  flag_integer("estimator_embedding_size", 8),
  flag_integer("estimator_hidden_units", c(100, 70, 50, 25)),

  flag_integer("eval_num_epochs", 5),
  flag_integer("eval_batch_size", 40),
  flag_integer("eval_delay_secs", 10),
  flag_integer("eval_steps", 100),

  flag_integer("train_num_epochs", 5),
  flag_integer("train_batch_size", 40),
  flag_integer("train_steps", 10)

)

# define estimator
estimator <- build_estimator(
  model_dir      = FLAGS$job_dir,
  embedding_size = FLAGS$estimator_embedding_size,
  hidden_units   = FLAGS$estimator_hidden_units
)

# run the experiment
experiment_fn <- generate_experiment_fn(estimator, FLAGS)
result <- learn_runner$run(experiment_fn, FLAGS$job_dir)

# extract generated artifacts
parameters <- result[[1]]
exports <- result[[2]]

# print results
print(parameters)
print(exports)


