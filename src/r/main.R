suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

data_dir <- Sys.getenv("DATA_DIR", "../data")

if (!file.exists(file.path(data_dir, "train.csv"))) {
  cat("Could not find train.csv in", data_dir, "\n")
  cat("Put train.csv, test.csv and gender_submission.csv in src/data\n")
  quit(status = 1)
}

# load training data
train <- read_csv(file.path(data_dir, "train.csv"), show_col_types = FALSE)
cat("Loaded train.csv, rows:", nrow(train), "cols:", ncol(train), "\n")
print(head(train))

# look at the data
cat("\nMissing values:\n")
print(colSums(is.na(train)))
cat("\nSurvival rate:", round(mean(train$Survived), 3), "\n")
cat("\nSurvival rate by sex:\n")
print(train %>% group_by(Sex) %>% summarise(rate = mean(Survived)))
cat("\nSurvival rate by class:\n")
print(train %>% group_by(Pclass) %>% summarise(rate = mean(Survived)))

# fill missing values using the training set
age_median <- median(train$Age, na.rm = TRUE)
fare_median <- median(train$Fare, na.rm = TRUE)
embarked_mode <- names(which.max(table(train$Embarked)))

clean <- function(df) {
  df %>%
    mutate(
      Age = ifelse(is.na(Age), age_median, Age),
      Fare = ifelse(is.na(Fare), fare_median, Fare),
      Embarked = factor(ifelse(is.na(Embarked), embarked_mode, Embarked),
                        levels = c("C", "Q", "S")),
      Sex = ifelse(Sex == "female", 1, 0)
    ) %>%
    select(any_of("Survived"), PassengerId, Pclass, Sex, Age, SibSp, Parch, Fare, Embarked)
}

train <- clean(train)
cat("\nFilled missing Age with median:", age_median, "\n")
cat("Filled missing Fare with median:", fare_median, "\n")
cat("Filled missing Embarked with:", embarked_mode, "\n")
cat("Changed Sex to 0 (male) / 1 (female)\n")
cat("Made Embarked a factor (C, Q, S)\n")
cat("Dropped Name, Ticket, Cabin\n")

# logistic regression
model <- glm(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked,
             data = train, family = binomial)
cat("\nModel coefficients:\n")
print(round(coef(model), 3))

train_pred <- ifelse(predict(model, train, type = "response") > 0.5, 1, 0)
cat("\nTraining accuracy:", round(mean(train_pred == train$Survived), 4), "\n")

# predict on test set
test <- read_csv(file.path(data_dir, "test.csv"), show_col_types = FALSE)
cat("\nLoaded test.csv, rows:", nrow(test), "cols:", ncol(test), "\n")
test <- clean(test)
test$Predicted <- ifelse(predict(model, test, type = "response") > 0.5, 1, 0)
cat("Predicted survivors:", sum(test$Predicted), "out of", nrow(test), "\n")
print(head(test[, c("PassengerId", "Predicted")]))

# test.csv has no Survived column, so compare to gender_submission.csv
answers_path <- file.path(data_dir, "gender_submission.csv")
if (file.exists(answers_path)) {
  answers <- read_csv(answers_path, show_col_types = FALSE)
  merged <- inner_join(test, answers, by = "PassengerId")
  cat("\nTest accuracy (vs gender_submission.csv):",
      round(mean(merged$Predicted == merged$Survived), 4), "\n")
} else {
  cat("\nNo gender_submission.csv found, skipping test accuracy\n")
}
