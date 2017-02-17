cloudml:::cloudml_run(
  task.arguments = list(
    "--train-file gs://tf-ml-workshop/widendeep/adult.data",
    "--eval-file gs://tf-ml-workshop/widendeep/adult.test",
    "--train-steps 1000",
    "--job-dir output"
  )
)
