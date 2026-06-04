import os

OLLAMA_HOST   = os.environ.get("OLLAMA_INTERNAL_URL", "http://ollama:11434")
OLLAMA_MODEL  = os.environ.get("OLLAMA_MODEL", "llama3.2:3b")
DATABASE_URL  = os.environ.get("DATABASE_URL", "postgresql://ailapyu:ailapyu123@db:5432/ailapyudb")
SYSTEM_PROMPT = os.environ.get("SYSTEM_PROMPT", "You are a helpful assistant.")
HISTORY_LIMIT = int(os.environ.get("HISTORY_LIMIT", 5))