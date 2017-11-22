library(tfestimators)

CSV_COLUMNS <- c(
  "age", "workclass", "fnlwgt", "education", "education_num",
  "marital_status", "occupation", "relationship", "race", "gender",
  "capital_gain", "capital_loss", "hours_per_week", "native_country",
  "income_bracket"
)

LABEL_COLUMN <- "income_bracket"

DEFAULTS <- lapply(
  list(0L, "", 0L, "", 0L, "", "", "", "", "", 0L, 0L, 0L, "", ""),
  list
)

FEATURE_COLUMNS <- feature_columns(

  gender = column_categorical_with_vocabulary_list(
    "gender",
    vocabulary_list = c(
      "Female",
      "Male"
    )
  ),

  race = column_categorical_with_vocabulary_list(
    "race",
    vocabulary_list = c(
      "Amer-Indian-Eskimo",
      "Asian-Pac-Islander",
      "Black",
      "Other",
      "White"
    )
  ),

  education = column_categorical_with_hash_bucket("education", hash_bucket_size = 1000L),
  marital_status = column_categorical_with_hash_bucket("marital_status", hash_bucket_size = 100L),
  relationship = column_categorical_with_hash_bucket("relationship", hash_bucket_size = 100L),
  workclass = column_categorical_with_hash_bucket("workclass", hash_bucket_size = 100L),
  occupation = column_categorical_with_hash_bucket("occupation", hash_bucket_size = 1000L),
  native_country = column_categorical_with_hash_bucket("native_country", hash_bucket_size = 1000L),

  age = column_numeric("age"),
  education_num = column_numeric("education_num"),
  capital_gain = column_numeric("capital_gain"),
  capital_loss = column_numeric("capital_loss"),
  hours_per_week = column_numeric("hours_per_week")

)

build_estimator <- function(embedding_size = 8L,
                            hidden_units = NULL)
{
  list2env(FEATURE_COLUMNS, envir = environment())

  age_buckets <- column_bucketized(
    age,
    boundaries = c(18, 25, 30, 35, 40, 45, 50, 55, 60, 65)
  )

  linear_feature_columns <- list(

    column_crossed(
      list("education", "occupation"),
      hash_bucket_size = 1E4L
    ),

    column_crossed(
      list(age_buckets, "race", "occupation"),
      hash_bucket_size = 1E6L
    ),

    column_crossed(
      list("native_country", "occupation"),
      hash_bucket_size = 1E4L
    ),

    age_buckets,

    gender,
    native_country,
    education,
    occupation,
    workclass,
    marital_status,
    relationship

  )

  dnn_feature_columns <- list(
    column_embedding(workclass, dimension = embedding_size),
    column_embedding(education, dimension = embedding_size),
    column_embedding(marital_status, dimension = embedding_size),
    column_embedding(gender, dimension = embedding_size),
    column_embedding(relationship, dimension = embedding_size),
    column_embedding(race, dimension = embedding_size),
    column_embedding(native_country, dimension = embedding_size),
    column_embedding(occupation, dimension = embedding_size),
    age,
    education_num,
    capital_gain,
    capital_loss,
    hours_per_week
  )

  dnn_linear_combined_classifier(
    linear_feature_columns = linear_feature_columns,
    dnn_feature_columns = dnn_feature_columns,
    dnn_hidden_units = hidden_units
  )
}

