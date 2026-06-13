import os

LOCAL_HOST = os.environ.get("LOCAL_HOST")
if not LOCAL_HOST:
    raise ValueError("LOCAL_HOST is not set")

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

DOMAIN_HTTPS = os.environ.get("DOMAIN_HTTPS")
if not DOMAIN_HTTPS:
    raise ValueError("DOMAIN_HTTPS is not set")

OLLAMA_INTERNAL_URL = os.environ.get("OLLAMA_INTERNAL_URL")
if not OLLAMA_INTERNAL_URL:
    raise ValueError("OLLAMA_INTERNAL_URL is not set")