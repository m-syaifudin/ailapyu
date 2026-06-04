FROM python:3.11-slim

WORKDIR /app

# curl needed for the healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run as non-root
RUN addgroup --system app && adduser --system --ingroup app app
USER app

EXPOSE 8000

# LOG_LEVEL is read from the environment (.env via docker-compose)
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port 8000 --log-level ${LOG_LEVEL:-info} --workers 1"]