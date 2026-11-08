# titanic-disaster

Logistic regression on the Kaggle Titanic dataset, done twice: once in Python and once in R. Each version has its own Dockerfile so you don't need either language installed locally.

The scripts do the same thing. They read `train.csv`, print a quick look at the data (missing values, survival rate by group), fill in the gaps, encode Sex and Embarked as numbers, fit the model, and report training accuracy. Then they predict on `test.csv` and report test accuracy.

## Layout

```
titanic-disaster/
├── README.md
├── .gitignore
└── src/
    ├── data/                  # csv files go here (ignored by git)
    ├── python/
    │   ├── Dockerfile
    │   ├── requirements.txt
    │   └── main.py
    └── r/
        ├── Dockerfile
        ├── install_packages.R
        └── main.R
```

## What you need

Docker Desktop (running), git, and a Kaggle account to grab the data.

## Setup

Clone it and `cd` in. Everything below assumes you're in the repo root.

```bash
git clone https://github.com/glyjtha/titanic-disaster.git
cd titanic-disaster
```

The data isn't included, so download it from https://www.kaggle.com/competitions/titanic/data (you'll have to log in and accept the competition rules first). Unzip it and drop the three csv files into `src/data`:

```bash
mkdir -p src/data
mv ~/Downloads/titanic/*.csv src/data/
```

Adjust the path if you unzipped somewhere else. `ls src/data` should show `gender_submission.csv`, `test.csv` and `train.csv`.

## Running it

Python:

```bash
docker build -t titanic-python src/python
docker run --rm -v "$(pwd)/src/data:/app/data" titanic-python
```

R (the first build is slow while it installs packages, give it a few minutes):

```bash
docker build -t titanic-r src/r
docker run --rm -v "$(pwd)/src/data:/app/data" titanic-r
```

The `-v` flag mounts your local `src/data` into the container, which is how the scripts find the csv files.

## Results

Roughly what I get:

| | Python | R |
|---|---|---|
| Training accuracy | 0.800 | 0.798 |
| Test accuracy | 0.940 | 0.943 |

Don't read too much into the test number. Kaggle's `test.csv` has no `Survived` column, so I'm scoring against `gender_submission.csv`, which is just Kaggle's sample file (it assumes every woman survived). It's a sanity check, not real accuracy.

## If something breaks

`path "src/python" not found` means you're not in the repo root.

`Could not find train.csv in /app/data` means either the csv files aren't in `src/data` or you left off the `-v` part.

`Cannot connect to the Docker daemon` means Docker Desktop isn't running yet.

