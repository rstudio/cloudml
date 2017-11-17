library(tensorflow)
library(tfestimators)

source("model.R")

# read in flags
FLAGS <- flags(

)

# train the model
train(model, mtcars_input_fn(train))
