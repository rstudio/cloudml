library(tensorflow)

source("model.R")

### Predict using Cloud ML local_predict -------------------------------------

# read in the data to use for predictions
data <- read.table(
  cloudml::gsutil_data("gs://rstudio-cloudml-demo-ml/census/data/local.adult.test"),
  col.names = CSV_COLUMNS,
  header = FALSE,
  sep = ",",
  stringsAsFactors = FALSE
)

# remove some columns
data$fnlwgt <- NULL
data[[LABEL_COLUMN]] <- NULL

# generate predictions
predictions <- cloudml:::local_predict("runs", data)

# print predictions
cat(yaml::as.yaml(predictions))



### Predict using TF estimator ----------------------------------------------

# estimator and input_fn for predction
estimator <- build_estimator("runs")
filename <- cloudml::gsutil_data("gs://rstudio-cloudml-demo-ml/census/data/local.adult.test")
input_fn <- predict_input_fn(filename)

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


