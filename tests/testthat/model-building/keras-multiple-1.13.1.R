reticulate::use_virtualenv("tf-1.13.1")

library(keras)

input1 <- layer_input(name = "input1", dtype = "float32", shape = c(1))
input2 <- layer_input(name = "input2", dtype = "float32", shape = c(1))

output1 <- layer_add(name = "output1", inputs = c(input1, input2))
output2 <- layer_add(name = "output2", inputs = c(input2, input1))

model <- keras_model(
  inputs = c(input1, input2),
  outputs = c(output1, output2)
)

export_savedmodel(model, "models/keras-multiple-1.13.1", as_text = TRUE)
