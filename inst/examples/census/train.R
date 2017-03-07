library(tensorflow)

source("model.R")

# define some aliases for commonly-used modules
learn                    <- tf$contrib$learn
metrics                  <- tf$contrib$metrics
learn_runner             <- learn$python$learn$learn_runner
saved_model_export_utils <- learn$python$learn$utils$saved_model_export_utils

# read application config and resolve data files
config <- cloudml::config()

# define estimator
estimator <- build_estimator(
  model_dir      = config$job_dir,
  embedding_size = config$estimator_embedding_size,
  hidden_units   = config$estimator_hidden_units
)

# run the experiment
experiment_fn <- generate_experiment_fn(config)
result <- learn_runner$run(experiment_fn, config$job_dir)

# extract generated artifacts
parameters <- result[[1]]
exports <- result[[2]]

# print results
print(parameters)
print(exports)


