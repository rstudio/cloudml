library(tensorflow)

source("model.R")

# path to dataset used for prediction
eval_file <- "local/gs/rstudio-cloudml-demo-ml/census/data/local.adult.data"

# define estimator
estimator <- build_estimator("jobs/local")

# use model to generate predictions with our input function
input_fn <- generate_input_fn(eval_file)
predictions <- iterate(estimator$predict(input_fn = input_fn))
classes <- iterate(estimator$predict_classes(input_fn = input_fn))
probabilities <- iterate(estimator$predict_proba(input_fn = input_fn))
