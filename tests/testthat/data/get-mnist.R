
x <- keras::dataset_mnist()
x$train$x <- t(apply(x$train$x, 1, function(x) x/255))
x$test$x <- t(apply(x$test$x, 1, function(x) x/255))

x$train$y <- keras::to_categorical(x$train$y, num_classes = 10)
x$test$y <- keras::to_categorical(x$test$y, num_classes = 10)

saveRDS(x, "data/mnist.rds")
