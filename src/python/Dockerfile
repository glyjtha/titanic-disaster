FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Data is mounted here at runtime (it is not included in the image or repo)
ENV DATA_DIR=/app/data

CMD ["python", "main.py"]
