#!/usr/bin/env sh
set -e
docker compose --env-file .env up -d --remove-orphans