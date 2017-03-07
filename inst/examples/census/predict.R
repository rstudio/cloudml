library(tensorflow)

source("model.R")

# read application config and resolve data files
config <- config::get()

# re-build estimator from jobs directory
experiment_fn <- generate_experiment_fn(config)
experiment <- experiment_fn("jobs/local")
estimator <- experiment$estimator

# extract predictions
input_fn <- experiment$eval_input_fn
predictions <- iterate(estimator$predict(input_fn = input_fn))
classes <- iterate(estimator$predict_classes(input_fn = input_fn))
probabilities <- iterate(estimator$predict_proba(input_fn = input_fn))
