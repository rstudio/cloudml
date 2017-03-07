library(tensorflow)

source("model.R")

# use test dataset for prediction
filename <- "local/gs/rstudio-cloudml-demo-ml/census/data/local.adult.test"

# rebuild estimator from existing job directory
estimator <- build_estimator("jobs/local")

# generate input function (request only 1 epoch
# so we just get one round of predictions)
input_fn <- generate_input_fn(filename = filename,
                              num_epochs = 1L,
                              batch_size = 10L)

# generate predictions
predictions   <- iterate(estimator$predict(input_fn = input_fn))
classes       <- iterate(estimator$predict_classes(input_fn = input_fn))
probabilities <- iterate(estimator$predict_proba(input_fn = input_fn))

# read in dataset and attach probabilities
dataset <- read.table(
  file = filename,
  header = FALSE,
  sep = ",",
  col.names = CSV_COLUMNS
)
dataset$predicted_classes <- as.numeric(classes)
dataset$predicted_probabilities <- as.numeric(lapply(probabilities, `[[`, 2))

# generate a simple plot
library(ggplot2)

# generate aesthetics (re-order occupation by average
# predicted probability)
aesthetics <- aes(
  x = reorder(occupation, predicted_probabilities, FUN = mean),
  y = predicted_probabilities
)

gg <- ggplot(dataset, aesthetics) +
  geom_boxplot() +
  coord_flip() +
  labs(
    x = "Occupation",
    y = "P(Income Bracket > 50K)",
    title = "P(Income Bracket > 50K) vs. Occupation"
  )

print(gg)
