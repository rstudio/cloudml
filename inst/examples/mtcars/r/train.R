library(tensorflow)
library(tfestimators)

source("model.R")

# train the model
train(model, mtcars_input_fn(train))
