.PHONY: up down build logs logs-api logs-ollama restart clean models pull shell-api shell-ollama

# ---- Lifecycle -------------------------------------------------------
up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build --no-cache api

restart:
	docker compose restart api

clean:
	docker compose down -v --remove-orphans

# ---- Logs ------------------------------------------------------------
logs:
	docker compose logs -f

logs-api:
	docker compose logs -f api

logs-ollama:
	docker compose logs -f ollama

# ---- Models ----------------------------------------------------------
# Usage: make pull MODEL=gemma2:2b
pull:
	docker compose exec ollama ollama pull $(MODEL)

models:
	docker compose exec ollama ollama list

# ---- Shell -----------------------------------------------------------
shell-api:
	docker compose exec api sh

shell-ollama:
	docker compose exec ollama bash