context("deploy")

models <- list.dirs("models/", recursive = FALSE, full.names = FALSE)

for (model in models) {

  test_that(paste0("Can deploy and predict model: ", model), {

    random_name <- paste0(
      gsub("[[:punct:]]", "_", model), "_",
      paste(sample(letters, 15, replace = TRUE), collapse = "")
    )

    cloudml_deploy(
      paste0("models/", model),
      name = random_name,
      version = "v1"
    )

    if (grepl("multiple", model)) {
      instances <- list(
        list(
          input1 = list(1),
          input2 = list(1)
        )
      )
    } else {
      instances <- list(rep(0,784))
    }

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

}


