#!/usr/bin/env sh
# ─────────────────────────────────────────────────────────────────────────────
# scripts/healthcheck.sh
# Detailed health check for ailapyu.  Run from the project root.
# ─────────────────────────────────────────────────────────────────────────────
set -e

# Load variables from .env (portable; no export needed for local use)
if [ -f .env ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^\s*#' .env | grep -v '^\s*$' | xargs)
fi

PORT="${OLLAMA_PORT:-11434}"
MODEL="${DEFAULT_MODEL:-llama3.1:8b}"
BASE="http://localhost:${PORT}"

pass() { printf "\033[32m✔\033[0m  %s\n" "$1"; }
fail() { printf "\033[31m✘\033[0m  %s\n" "$1"; exit 1; }
info() { printf "\033[34m→\033[0m  %s\n" "$1"; }

echo ""
info "ailapyu health check"
echo "───────────────────────────────────────────────────────────"

# 1. Container running?
docker inspect --format "{{.State.Status}}" ailapyu_ollama 2>/dev/null | grep -q running \
  && pass "Container ailapyu_ollama is running" \
  || fail "Container ailapyu_ollama is NOT running"

# 2. Ollama API reachable?
curl -sf "${BASE}/api/tags" -o /dev/null \
  && pass "Ollama API is reachable at ${BASE}" \
  || fail "Ollama API not reachable at ${BASE}"

# 3. Default model present?
curl -sf "${BASE}/api/tags" \
  | python3 -c "import sys,json; models=[m['name'] for m in json.load(sys.stdin)['models']]; print('\n'.join(models))" \
  | grep -q "^${MODEL}" \
  && pass "Model '${MODEL}' is present" \
  || fail "Model '${MODEL}' not found – run: make pull-model"

# 4. OpenAI /v1/models endpoint?
curl -sf "${BASE}/v1/models" -o /dev/null \
  && pass "OpenAI-compatible /v1/models endpoint OK" \
  || fail "OpenAI /v1/models endpoint not responding"

# 5. Chat completion round-trip?
RESPONSE=$(curl -sf "${BASE}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"${MODEL}\",\"messages\":[{\"role\":\"user\",\"content\":\"Say: PONG\"}],\"max_tokens\":10}")
echo "${RESPONSE}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'])" >/dev/null 2>&1 \
  && pass "Chat completion round-trip successful" \
  || fail "Chat completion returned unexpected response"

echo "───────────────────────────────────────────────────────────"
info "All checks passed.  Service is healthy."
echo ""