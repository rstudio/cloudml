library(tfestimators)

mtcars_input_fn <- function(data) {
  input_fn(data,
           features = c("disp", "cyl"),
           response = "mpg")
}

cols <- feature_columns(
  column_numeric("disp", "cyl")
)

model <- linear_regressor(feature_columns = cols)

indices <- sample(1:nrow(mtcars), size = 0.80 * nrow(mtcars))
train <- mtcars[indices, ]
test  <- mtcars[-indices, ]
