"""
ailapyu — lightweight OpenAI-compatible AI service backed by Ollama.
"""

from __future__ import annotations

import asyncio
import time
import uuid
from contextlib import asynccontextmanager
from typing import AsyncIterator, Literal

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings


# ──────────────────────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────────────────────

class Settings(BaseSettings):
    ollama_base_url: str = "http://ollama:11434"
    default_model: str = "qwen2.5:1.5b"
    ollama_retry_interval: int = 5
    ollama_max_retries: int = 60
    ollama_request_timeout: int = 300

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()


# ──────────────────────────────────────────────────────────────────────────────
# HTTP client (shared, with connection pooling)
# ──────────────────────────────────────────────────────────────────────────────

http_client: httpx.AsyncClient | None = None


def get_client() -> httpx.AsyncClient:
    assert http_client is not None, "HTTP client not initialised"
    return http_client


# ──────────────────────────────────────────────────────────────────────────────
# Startup helpers
# ──────────────────────────────────────────────────────────────────────────────

async def _wait_for_ollama() -> None:
    """Poll Ollama's /api/tags until it responds or we exhaust retries."""
    client = get_client()
    for attempt in range(1, settings.ollama_max_retries + 1):
        try:
            resp = await client.get(
                f"{settings.ollama_base_url}/api/tags", timeout=5
            )
            if resp.status_code == 200:
                print(f"[ailapyu] Ollama is ready (attempt {attempt}).")
                return
        except (httpx.ConnectError, httpx.ReadError, httpx.TimeoutException):
            pass

        print(
            f"[ailapyu] Waiting for Ollama… attempt {attempt}/{settings.ollama_max_retries}"
        )
        await asyncio.sleep(settings.ollama_retry_interval)

    raise RuntimeError(
        f"Ollama did not become available after "
        f"{settings.ollama_max_retries * settings.ollama_retry_interval}s."
    )


async def _wait_for_model() -> None:
    """Verify the default model is present in Ollama's local library."""
    client = get_client()
    model = settings.default_model

    for attempt in range(1, settings.ollama_max_retries + 1):
        try:
            resp = await client.get(
                f"{settings.ollama_base_url}/api/tags", timeout=10
            )
            if resp.status_code == 200:
                models = [m["name"] for m in resp.json().get("models", [])]
                # Accept both "qwen2.5:1.5b" and "qwen2.5:1.5b" (exact or prefix)
                if any(m == model or m.startswith(model.split(":")[0]) for m in models):
                    print(f"[ailapyu] Model '{model}' is available.")
                    return
        except Exception:
            pass

        print(
            f"[ailapyu] Model '{model}' not yet ready… attempt {attempt}/{settings.ollama_max_retries}"
        )
        await asyncio.sleep(settings.ollama_retry_interval)

    raise RuntimeError(
        f"Model '{model}' was not ready after waiting. "
        "Check model-init container logs."
    )


# ──────────────────────────────────────────────────────────────────────────────
# Lifespan
# ──────────────────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    global http_client

    http_client = httpx.AsyncClient(
        timeout=httpx.Timeout(settings.ollama_request_timeout),
        limits=httpx.Limits(max_connections=20, max_keepalive_connections=10),
    )

    print("[ailapyu] Starting up — waiting for Ollama…")
    await _wait_for_ollama()
    await _wait_for_model()
    print("[ailapyu] Ready to serve requests.")

    yield

    await http_client.aclose()
    print("[ailapyu] Shutdown complete.")


# ──────────────────────────────────────────────────────────────────────────────
# App
# ──────────────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="ailapyu",
    description="Lightweight OpenAI-compatible AI service powered by Ollama.",
    version="1.0.0",
    lifespan=lifespan,
)


# ──────────────────────────────────────────────────────────────────────────────
# OpenAI-compatible schemas
# ──────────────────────────────────────────────────────────────────────────────

class ChatMessage(BaseModel):
    role: Literal["system", "user", "assistant", "tool"]
    content: str | None = None
    name: str | None = None


class ChatCompletionRequest(BaseModel):
    model: str | None = None
    messages: list[ChatMessage]
    temperature: float | None = Field(default=None, ge=0.0, le=2.0)
    top_p: float | None = Field(default=None, ge=0.0, le=1.0)
    max_tokens: int | None = Field(default=None, ge=1)
    stream: bool = False
    stop: str | list[str] | None = None
    frequency_penalty: float | None = None
    presence_penalty: float | None = None
    seed: int | None = None
    user: str | None = None


class ChoiceDelta(BaseModel):
    role: str | None = None
    content: str | None = None


class StreamChoice(BaseModel):
    index: int
    delta: ChoiceDelta
    finish_reason: str | None = None


class StreamChunk(BaseModel):
    id: str
    object: str = "chat.completion.chunk"
    created: int
    model: str
    choices: list[StreamChoice]


class ChoiceMessage(BaseModel):
    role: str
    content: str


class Choice(BaseModel):
    index: int
    message: ChoiceMessage
    finish_reason: str = "stop"


class Usage(BaseModel):
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


class ChatCompletionResponse(BaseModel):
    id: str
    object: str = "chat.completion"
    created: int
    model: str
    choices: list[Choice]
    usage: Usage


# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

def _resolve_model(requested: str | None) -> str:
    return requested or settings.default_model


def _build_ollama_payload(req: ChatCompletionRequest, model: str) -> dict:
    options: dict = {}
    if req.temperature is not None:
        options["temperature"] = req.temperature
    if req.top_p is not None:
        options["top_p"] = req.top_p
    if req.max_tokens is not None:
        options["num_predict"] = req.max_tokens
    if req.seed is not None:
        options["seed"] = req.seed

    payload: dict = {
        "model": model,
        "messages": [m.model_dump(exclude_none=True) for m in req.messages],
        "stream": req.stream,
    }
    if options:
        payload["options"] = options
    if req.stop:
        payload["stop"] = req.stop if isinstance(req.stop, list) else [req.stop]

    return payload


def _token_estimate(text: str) -> int:
    """Rough token estimate: ~4 chars per token."""
    return max(1, len(text) // 4)


async def _call_ollama_with_retry(payload: dict, stream: bool) -> httpx.Response:
    """Call Ollama /api/chat with simple retry on transient errors."""
    client = get_client()
    url = f"{settings.ollama_base_url}/api/chat"

    for attempt in range(1, 4):  # up to 3 attempts
        try:
            if stream:
                # Return the response object so the caller can stream it
                req = client.build_request("POST", url, json=payload)
                response = await client.send(req, stream=True)
                response.raise_for_status()
                return response
            else:
                response = await client.post(url, json=payload)
                response.raise_for_status()
                return response
        except (httpx.ConnectError, httpx.RemoteProtocolError) as exc:
            if attempt == 3:
                raise
            wait = attempt * 2
            print(f"[ailapyu] Ollama call failed (attempt {attempt}): {exc}. Retrying in {wait}s…")
            await asyncio.sleep(wait)

    raise RuntimeError("Unreachable")


# ──────────────────────────────────────────────────────────────────────────────
# Routes
# ──────────────────────────────────────────────────────────────────────────────

@app.get("/health")
async def health() -> dict:
    """Simple liveness probe."""
    return {"status": "ok", "service": "ailapyu"}


@app.get("/v1/models")
async def list_models() -> dict:
    """Return available models from Ollama in OpenAI format."""
    client = get_client()
    try:
        resp = await client.get(f"{settings.ollama_base_url}/api/tags", timeout=10)
        resp.raise_for_status()
        ollama_models = resp.json().get("models", [])
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Failed to fetch models: {exc}")

    data = [
        {
            "id": m["name"],
            "object": "model",
            "created": int(time.time()),
            "owned_by": "ollama",
        }
        for m in ollama_models
    ]
    return {"object": "list", "data": data}


@app.post("/v1/chat/completions")
async def chat_completions(req: ChatCompletionRequest) -> JSONResponse | StreamingResponse:
    """OpenAI-compatible chat completions endpoint."""
    model = _resolve_model(req.model)
    payload = _build_ollama_payload(req, model)

    completion_id = f"chatcmpl-{uuid.uuid4().hex}"
    created_ts = int(time.time())

    # ── Streaming ──────────────────────────────────────────────────────────────
    if req.stream:
        async def event_stream() -> AsyncIterator[str]:
            try:
                response = await _call_ollama_with_retry(payload, stream=True)
                async for line in response.aiter_lines():
                    if not line.strip():
                        continue
                    try:
                        import json
                        chunk_data = json.loads(line)
                    except Exception:
                        continue

                    message = chunk_data.get("message", {})
                    content = message.get("content", "")
                    done = chunk_data.get("done", False)

                    finish_reason = "stop" if done else None

                    chunk = StreamChunk(
                        id=completion_id,
                        created=created_ts,
                        model=model,
                        choices=[
                            StreamChoice(
                                index=0,
                                delta=ChoiceDelta(
                                    role="assistant" if not content else None,
                                    content=content or None,
                                ),
                                finish_reason=finish_reason,
                            )
                        ],
                    )
                    yield f"data: {chunk.model_dump_json()}\n\n"

                    if done:
                        break

                yield "data: [DONE]\n\n"

            except httpx.HTTPStatusError as exc:
                error_body = {"error": {"message": exc.response.text, "type": "upstream_error"}}
                import json
                yield f"data: {json.dumps(error_body)}\n\n"
            except Exception as exc:
                import json
                error_body = {"error": {"message": str(exc), "type": "internal_error"}}
                yield f"data: {json.dumps(error_body)}\n\n"

        return StreamingResponse(
            event_stream(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "X-Accel-Buffering": "no",
            },
        )

    # ── Non-streaming ──────────────────────────────────────────────────────────
    try:
        response = await _call_ollama_with_retry(payload, stream=False)
    except httpx.HTTPStatusError as exc:
        raise HTTPException(
            status_code=exc.response.status_code,
            detail=f"Ollama error: {exc.response.text}",
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Upstream error: {exc}")

    data = response.json()
    assistant_content = data.get("message", {}).get("content", "")

    prompt_text = " ".join(m.content or "" for m in req.messages)
    prompt_tokens = _token_estimate(prompt_text)
    completion_tokens = _token_estimate(assistant_content)

    result = ChatCompletionResponse(
        id=completion_id,
        created=created_ts,
        model=model,
        choices=[
            Choice(
                index=0,
                message=ChoiceMessage(role="assistant", content=assistant_content),
                finish_reason="stop",
            )
        ],
        usage=Usage(
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_tokens=prompt_tokens + completion_tokens,
        ),
    )
    return JSONResponse(content=result.model_dump())