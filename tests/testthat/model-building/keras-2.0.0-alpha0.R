
reticulate::use_virtualenv("tf-2.0.0")

# Packages ----------------------------------------------------------------

library(tensorflow)
library(keras)


mnist <- readRDS("data/mnist.rds")
next_batch <- function() {
  ids <- sample.int(nrow(mnist$train$x), size = 32)
  list(
    x = mnist$train$x[ids,],
    y = mnist$train$y[ids,]
  )
}

model <- keras_model_sequential() %>%
  layer_dense(units = 10, input_shape = 784, activation = "softmax")

model %>% compile(optimizer = "sgd", loss = "categorical_crossentropy",
                  metrics = "accuracy")

model %>% fit(mnist$train$x, mnist$train$y, epochs = 1)

evaluate(model, mnist$test$x, mnist$test$y)

export_savedmodel(
  model,
  "models/keras-2.0.0-alpha0/"
  )




