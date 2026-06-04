#!/usr/bin/env sh
# ─────────────────────────────────────────────────────────────────────────────
# scripts/pull-model.sh
# Pull a model via the Ollama REST API.
# Usage:  ./scripts/pull-model.sh [model-name]
#         ./scripts/pull-model.sh mistral:latest
# If no argument is given, DEFAULT_MODEL from .env is used.
# ─────────────────────────────────────────────────────────────────────────────
set -e

if [ -f .env ]; then
  export $(grep -v '^\s*#' .env | grep -v '^\s*$' | xargs)
fi

MODEL="${1:-${DEFAULT_MODEL:-llama3.2:3b}}"
PORT="${OLLAMA_PORT:-11434}"

echo "Pulling model: ${MODEL} …"
curl -sf --max-time 600 \
  -X POST "http://localhost:${PORT}/api/pull" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"${MODEL}\", \"stream\": false}"

echo ""
echo "Done. Run 'make test' to verify."