source("project/config.R")
paths <- project_paths

raw_data_path <- paths$raw_data_path
processed_data_path <- paths$processed_data_path

if (!file.exists(raw_data_path)) {
  stop("Dataset non trovato in: ", raw_data_path)
}

data <- read.csv(raw_data_path)


prepared_data <- data


prepared_data$BMI_categoriale <- cut(
  prepared_data$BMI,
  breaks = c(-Inf, 18.5, 25, 30, Inf),
  labels = c("sottopeso", "normopeso", "sovrappeso", "obesita"),
  right = FALSE
)

prepared_data$MentHlth_categoriale <- "zero_giorni"
positive_index <- prepared_data$MentHlth > 0
positive_ranks <- rank(prepared_data$MentHlth[positive_index], ties.method = "first")
rank_breaks <- quantile(positive_ranks, probs = seq(0, 1, 0.25), na.rm = TRUE)

prepared_data$MentHlth_categoriale[positive_index] <- as.character(
  cut(
    positive_ranks,
    breaks = rank_breaks,
    include.lowest = TRUE,
    labels = c("basso", "medio_basso", "medio_alto", "alto")
  )
)

prepared_data$PhysHlth_categoriale <- cut(
  prepared_data$PhysHlth,
  breaks = c(-Inf, 1, 6, 11, 21, Inf),
  labels = c("0_giorni", "1_5", "6_10", "11_20", "21_30"),
  right = FALSE
)

prepared_data <- prepared_data[, !(names(prepared_data) %in% c("BMI", "MentHlth", "PhysHlth"))]

write.csv(prepared_data, processed_data_path, row.names = FALSE)
cat("Dataset processato salvato in:", processed_data_path, "\n")

set.seed(123)

n_obs <- nrow(prepared_data)
shuffled_indices <- sample(n_obs)

train_end <- floor(0.70 * n_obs)
validation_end <- train_end + floor(0.20 * n_obs)

training_set <- prepared_data[shuffled_indices[1:train_end], ]
validation_set <- prepared_data[shuffled_indices[(train_end + 1):validation_end], ]
test_set <- prepared_data[shuffled_indices[(validation_end + 1):n_obs], ]

training_set_path <- file.path("data", "processed", "training_set.csv")
validation_set_path <- file.path("data", "processed", "validation_set.csv")
test_set_path <- file.path("data", "processed", "test_set.csv")

write.csv(training_set, training_set_path, row.names = FALSE)
write.csv(validation_set, validation_set_path, row.names = FALSE)
write.csv(test_set, test_set_path, row.names = FALSE)

cat("Training set salvato in:", training_set_path, "\n")
cat("Validation set salvato in:", validation_set_path, "\n")
cat("Test set salvato in:", test_set_path, "\n")
