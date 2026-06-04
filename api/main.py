import asyncio
import logging
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.config import get_settings
from routers import chat, models

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
settings = get_settings()

logging.basicConfig(
    level=settings.log_level.upper(),
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Model auto-pull (runs in background — does not block startup)
# ---------------------------------------------------------------------------

async def _pull_model_if_needed(ollama_url: str, model: str) -> None:
    """Check if model exists; pull it from Ollama registry if not."""
    await asyncio.sleep(2)  # give Ollama a moment after healthcheck passes
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(f"{ollama_url}/api/tags")
            existing = [m["name"] for m in resp.json().get("models", [])]

        if model in existing:
            logger.info("Model '%s' already available", model)
            return

        logger.info("Pulling model '%s' — this may take a few minutes …", model)
        async with httpx.AsyncClient(timeout=httpx.Timeout(600.0, connect=10.0)) as client:
            async with client.stream(
                "POST", f"{ollama_url}/api/pull", json={"name": model}
            ) as resp:
                async for line in resp.aiter_lines():
                    if line:
                        logger.info("[pull] %s", line)

        logger.info("Model '%s' ready", model)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Auto-pull failed (%s) — start manually: make pull MODEL=%s", exc, model)


# ---------------------------------------------------------------------------
# Lifespan
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    cfg = get_settings()
    logger.info(
        "AiLapYu starting | model=%s | ollama=%s", cfg.default_model, cfg.ollama_base_url
    )
    pull_task = None
    if cfg.auto_pull_model:
        pull_task = asyncio.create_task(
            _pull_model_if_needed(cfg.ollama_base_url, cfg.default_model)
        )
    yield
    if pull_task and not pull_task.done():
        pull_task.cancel()


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = FastAPI(
    title="AiLapYu",
    description="OpenAI-compatible local LLM API — powered by Ollama + FastAPI",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(chat.router, tags=["Chat"])
app.include_router(models.router, tags=["Models"])


@app.get("/health", tags=["System"])
async def health():
    return {"status": "ok", "service": "ailapyu"}