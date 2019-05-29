context("deploy")

models <- list.dirs("models/", recursive = FALSE, full.names = FALSE)

for (model in models) {

  test_that(paste0("Can deploy and predict model: ", model), {

    cloudml_deploy(
      paste0("models/", model),
      name = gsub("[[:punct:]]", "_", model),
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
      name = gsub("[[:punct:]]", "_", model),
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
        gsub("[[:punct:]]", "_", model)
      )
    )

    gcloud_exec(
      args = c(
        "ai-platform",
        "models",
        "delete",
        gsub("[[:punct:]]", "_", model)
      )
    )

  })

}


