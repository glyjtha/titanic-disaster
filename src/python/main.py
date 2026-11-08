import os

import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score

data_dir = os.getenv("DATA_DIR", "../data")

if not os.path.exists(f"{data_dir}/train.csv"):
    print(f"Could not find train.csv in {data_dir}")
    print("Put train.csv, test.csv and gender_submission.csv in src/data")
    raise SystemExit(1)

# load training data
train = pd.read_csv(f"{data_dir}/train.csv")
print("Loaded train.csv, shape:", train.shape)
print(train.head())

# look at the data
print("\nMissing values:")
print(train.isnull().sum())
print("\nSurvival rate:", round(train["Survived"].mean(), 3))
print("\nSurvival rate by sex:")
print(train.groupby("Sex")["Survived"].mean())
print("\nSurvival rate by class:")
print(train.groupby("Pclass")["Survived"].mean())

# fill missing values using the training set
age_median = train["Age"].median()
fare_median = train["Fare"].median()
embarked_mode = train["Embarked"].mode()[0]

features = ["Pclass", "Sex", "Age", "SibSp", "Parch", "Fare", "Embarked"]


def clean(df):
    df = df.copy()
    df["Age"] = df["Age"].fillna(age_median)
    df["Fare"] = df["Fare"].fillna(fare_median)
    df["Embarked"] = df["Embarked"].fillna(embarked_mode)
    df["Sex"] = df["Sex"].map({"male": 0, "female": 1})
    return pd.get_dummies(df[features], columns=["Embarked"], dtype=int)


X_train = clean(train)
y_train = train["Survived"]

print("\nFilled missing Age with median:", age_median)
print("Filled missing Fare with median:", fare_median)
print("Filled missing Embarked with:", embarked_mode)
print("Changed Sex to 0 (male) / 1 (female)")
print("Made dummy columns for Embarked")
print("Dropped PassengerId, Name, Ticket, Cabin")
print("Features used:", list(X_train.columns))

# logistic regression
model = LogisticRegression(max_iter=1000)
model.fit(X_train, y_train)

print("\nModel coefficients:")
for col, coef in zip(X_train.columns, model.coef_[0]):
    print(f"  {col}: {coef:.3f}")

train_acc = accuracy_score(y_train, model.predict(X_train))
print("\nTraining accuracy:", round(train_acc, 4))

# predict on test set
test = pd.read_csv(f"{data_dir}/test.csv")
print("\nLoaded test.csv, shape:", test.shape)

X_test = clean(test).reindex(columns=X_train.columns, fill_value=0)
test["Predicted"] = model.predict(X_test)
print("Predicted survivors:", test["Predicted"].sum(), "out of", len(test))
print(test[["PassengerId", "Predicted"]].head())

# test.csv has no Survived column, so compare to gender_submission.csv
if os.path.exists(f"{data_dir}/gender_submission.csv"):
    answers = pd.read_csv(f"{data_dir}/gender_submission.csv")
    merged = test.merge(answers, on="PassengerId")
    test_acc = accuracy_score(merged["Survived"], merged["Predicted"])
    print("\nTest accuracy (vs gender_submission.csv):", round(test_acc, 4))
else:
    print("\nNo gender_submission.csv found, skipping test accuracy")
