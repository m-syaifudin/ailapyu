#!/usr/bin/env sh
set -e
docker compose --env-file .env logs -f ollama