FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 8000
HEALTHCHECK CMD curl -fsS http://127.0.0.1:8000/api/health || exit 1
CMD ["gunicorn", "-b", "0.0.0.0:8000", "app:app"]
