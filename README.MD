# AiLapYu 🤖

> Local AI API — OpenAI-compatible, powered by **Ollama + FastAPI**, deployed via Docker Compose.

---

## Architecture

```
Client (curl / OpenWebUI / LangChain)
        │  HTTP  (OpenAI-compatible)
        ▼
┌────────────────────┐
│   FastAPI  :8000   │  ← ailapyu-api
│   /v1/chat/…       │
│   /v1/models       │
│   /health          │
└────────┬───────────┘
         │  HTTP  (Ollama API)
         ▼
┌────────────────────┐
│   Ollama   :11434  │  ← ailapyu-ollama
│   llama3.2:1b      │     (model stored in Docker volume)
└────────────────────┘
```

---

## Prerequisites

- Docker ≥ 24 with the Compose plugin (`docker compose version`)
- 2 vCPU / 4 GB RAM VPS (minimum)

---

## Quick Start

```bash
# 1. Clone / copy project
git clone <your-repo> ailapyu && cd ailapyu

# 2. Create your .env (defaults work out of the box)
cp .env.example .env

# 3. Build and start
docker compose up -d

# 4. Watch logs — model pull happens in background on first run
make logs-api

# 5. Test
curl http://localhost:8000/health
curl http://localhost:8000/v1/models
```

---

## Configuration (`.env`)

| Variable | Default | Description |
|---|---|---|
| `DEFAULT_MODEL` | `llama3.2:1b` | Model served by default |
| `AUTO_PULL_MODEL` | `true` | Pull model automatically on startup |
| `OLLAMA_BASE_URL` | `http://ollama:11434` | Internal Ollama URL (keep as-is for Docker) |
| `OLLAMA_MEMORY_LIMIT` | `3g` | Max RAM for the Ollama container |
| `OLLAMA_KEEP_ALIVE` | `5m` | How long to keep model loaded in VRAM/RAM |
| `API_PORT` | `8000` | Exposed API port |
| `API_KEY` | *(empty)* | Bearer token — leave blank to disable auth |
| `LOG_LEVEL` | `info` | `debug` / `info` / `warning` / `error` |

---

## API Endpoints

### `POST /v1/chat/completions`

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:1b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

Streaming:

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Count to 5"}], "stream": true}'
```

With API key enabled:

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer your-secret-key" \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hi"}]}'
```

### `GET /v1/models`

```bash
curl http://localhost:8000/v1/models
```

### `GET /health`

```bash
curl http://localhost:8000/health
```

---

## Model Guide for 4 GB VPS

| Model | Size | RAM needed | Notes |
|---|---|---|---|
| `qwen2.5:0.5b` | ~400 MB | ~1 GB | Ultra-light, fastest |
| `llama3.2:1b` | ~1.3 GB | ~2.6 GB | ✅ **Recommended default** |
| `phi3:mini` | ~2.3 GB | ~4.6 GB | Smarter but tight on 4 GB |

Pull an additional model at any time:

```bash
make pull MODEL=qwen2.5:0.5b
# or
docker compose exec ollama ollama pull qwen2.5:0.5b
```

---

## Makefile Commands

```
make up            Start all services
make down          Stop all services
make build         Rebuild the API image (no cache)
make restart       Restart only the API service
make logs          Follow all logs
make logs-api      Follow API logs only
make logs-ollama   Follow Ollama logs only
make models        List downloaded models
make pull MODEL=x  Pull a model (e.g. make pull MODEL=gemma2:2b)
make shell-api     Shell into the API container
make shell-ollama  Shell into the Ollama container
make clean         Stop + remove all volumes (⚠ deletes downloaded models)
```

---

## Adding API Key Auth

Generate a key and set it in `.env`:

```bash
openssl rand -hex 16
# → paste output as API_KEY=<value>
```

Then restart:

```bash
docker compose restart api
```

---

## Upgrading Later

**Bigger VPS (8+ GB RAM):** Update `OLLAMA_MEMORY_LIMIT=6g` in `.env` and try `llama3.2:3b` or `phi4:14b`.

**GPU support:** Replace the `ollama` service image with the GPU variant and add runtime config:

```yaml
# docker-compose.yml — ollama service
image: ollama/ollama:latest
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

**Add logging + DB (next step):** The project is structured for easy extension — just add new routers and a `database` service to `docker-compose.yml`.