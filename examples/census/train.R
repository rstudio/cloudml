library(tensorflow)

source("model.R")

# define some aliases for commonly-used modules
learn                    <- tf$contrib$learn
metrics                  <- tf$contrib$metrics
learn_runner             <- learn$python$learn$learn_runner
saved_model_export_utils <- learn$python$learn$utils$saved_model_export_utils

# read application config and resolve data files
FLAGS <- flags(

  flag_string("train_file", "gs://cloudml-public/census/data/adult.data.csv"),
  flag_string("eval_file", "gs://cloudml-public/census/data/adult.test.csv"),

  flag_numeric("estimator_embedding_size", 8),
  flag_numeric("estimator_hidden_units", c(100, 70, 50, 25)),

  flag_numeric("eval_num_epochs", 10),
  flag_numeric("eval_batch_size", 40),
  flag_numeric("eval_delay_secs", 10),
  flag_numeric("eval_steps", 100),

  flag_numeric("train_num_epcohs", 10),
  flag_numeric("train_batch_size", 40),
  flag_numeric("train_steps", 10)

)

config <- cloudml::project_config()

# define estimator
estimator <- build_estimator(
  model_dir      = config$job_dir,
  embedding_size = config$estimator_embedding_size,
  hidden_units   = config$estimator_hidden_units
)

# run the experiment
experiment_fn <- generate_experiment_fn(estimator, config)
result <- learn_runner$run(experiment_fn, config$job_dir)

# extract generated artifacts
parameters <- result[[1]]
exports <- result[[2]]

# print results
print(parameters)
print(exports)


