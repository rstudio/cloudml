context("deploy")

test_that("Can deploy a Keras model", {
  skip_on_appveyor()

  library(keras)

  input1 <- layer_input(name = "input1", dtype = "float32", shape = c(1))
  input2 <- layer_input(name = "input2", dtype = "float32", shape = c(1))

  output1 <- layer_add(name = "output1", inputs = c(input1, input2))
  output2 <- layer_add(name = "output2", inputs = c(input2, input1))

  model <- keras_model(
    inputs = c(input1, input2),
    outputs = c(output1, output2)
  )

  model_path <- "keras_model"

  export_savedmodel(model, model_path)

  random_name <- paste0(
    model_path, "_",
    paste(sample(letters, 15, replace = TRUE), collapse = "")
  )

  cloudml_deploy(
    model_path,
    name = random_name,
    version = "v1"
  )

  instances <- list(
    list(
      input1 = list(1),
      input2 = list(1)
    )
  )

  pred <- cloudml_predict(
    instances = instances,
    name = random_name,
    version = "v1"
  )

  expect_true(is.numeric(unlist(pred)))

  gcloud_exec(
    args = c(
      "ai-platform",
      "versions",
      "delete",
      "v1",
      "--model",
      random_name
    )
  )

  gcloud_exec(
    args = c(
      "ai-platform",
      "models",
      "delete",
      random_name
    )
  )

})


