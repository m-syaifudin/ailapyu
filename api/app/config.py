import os

# OLLAMA_HOST   = os.environ.get("OLLAMA_INTERNAL_URL", "")
# OLLAMA_MODEL  = os.environ.get("OLLAMA_MODEL", "")
# DATABASE_URL  = os.environ.get("DATABASE_URL", "")
# SYSTEM_PROMPT = os.environ.get("SYSTEM_PROMPT", "")
# HISTORY_LIMIT = int(os.environ.get("HISTORY_LIMIT", 5))

OLLAMA_HOST = os.environ.get("OLLAMA_INTERNAL_URL")
if not OLLAMA_HOST:
    raise ValueError("OLLAMA_INTERNAL_URL is not set")

OLLAMA_MODEL = os.environ.get("DEFAULT_MODEL")
if not OLLAMA_MODEL:
    raise ValueError("DEFAULT_MODEL is not set")

DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL is not set")

SYSTEM_PROMPT = os.environ.get("SYSTEM_PROMPT")
if not SYSTEM_PROMPT:
    raise ValueError("SYSTEM_PROMPT is not set")

HISTORY_LIMIT = int(os.environ.get("HISTORY_LIMIT"))
if not HISTORY_LIMIT:
    raise ValueError("HISTORY_LIMIT is not set")