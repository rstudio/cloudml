library(tensorflow)
library(tfestimators)

source("model.R")

# read in flags
FLAGS <- flags(

  flag_string("train_file", "gs://rstudio-cloudml/census/data/adult.data.csv"),
  flag_string("eval_file", "gs://rstudio-cloudml/census/data/adult.test.csv"),

  flag_integer("estimator_embedding_size", 8),
  flag_string("estimator_hidden_units", "[100, 70, 50, 25]"),

  flag_integer("eval_num_epochs", 5),
  flag_integer("eval_batch_size", 40),
  flag_integer("eval_delay_secs", 10),
  flag_integer("eval_steps", 100),

  flag_integer("train_num_epochs", 5),
  flag_integer("train_batch_size", 40),
  flag_integer("train_steps", 10)

)

FLAGS$estimator_hidden_units <-
  yaml::yaml.load(FLAGS$estimator_hidden_units)

# define estimator
estimator <- build_estimator(
  embedding_size = FLAGS$estimator_embedding_size,
  hidden_units   = FLAGS$estimator_hidden_units
)

# define input function
train_file <- cloudml::gsutil_data(FLAGS$train_file)
train_data <- readr::read_csv(
  train_file,
  col_names = CSV_COLUMNS,
  trim_ws = TRUE,
  progress = FALSE
)

# tensorflow doesn't like string inputs?
train_data$income_bracket <- as.integer(as.factor(train_data$income_bracket)) - 1L

train_input_fn <- input_fn(
  train_data,
  response = LABEL_COLUMN,
  features = setdiff(names(train_data), LABEL_COLUMN)
)

train(estimator,
      input_fn = train_input_fn,
      verbose = FALSE,
      view_metrics = FALSE,
      debug_logging = TRUE,
      steps = 100)
