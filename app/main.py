import os
import time
import uuid

import httpx

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from tenacity import retry
from tenacity import stop_after_attempt
from tenacity import wait_fixed

OLLAMA_HOST = os.getenv(
    "OLLAMA_HOST",
    "http://ollama:11434"
)

MODEL = os.getenv(
    "OLLAMA_MODEL",
    "qwen2.5:1.5b"
)

TIMEOUT = int(
    os.getenv(
        "OLLAMA_TIMEOUT",
        "120"
    )
)

RETRIES = int(
    os.getenv(
        "OLLAMA_MAX_RETRIES",
        "5"
    )
)

app = FastAPI(
    title="ailapyu",
    version="1.0.0"
)


class Message(BaseModel):
    role: str
    content: str


class ChatCompletionRequest(BaseModel):
    model: str | None = None
    messages: list[Message]
    temperature: float | None = 0.7
    stream: bool | None = False


@app.on_event("startup")
async def startup():
    await wait_for_ollama()


async def wait_for_ollama():

    for _ in range(120):
        try:
            async with httpx.AsyncClient() as client:
                r = await client.get(
                    f"{OLLAMA_HOST}/api/tags",
                    timeout=5
                )

                if r.status_code == 200:
                    return

        except Exception:
            pass

        time.sleep(2)

    raise RuntimeError(
        "Ollama not ready"
    )


@retry(
    stop=stop_after_attempt(RETRIES),
    wait=wait_fixed(2),
)
async def call_ollama(payload):

    async with httpx.AsyncClient() as client:

        response = await client.post(
            f"{OLLAMA_HOST}/api/chat",
            json=payload,
            timeout=TIMEOUT
        )

        response.raise_for_status()

        return response.json()


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "model": MODEL
    }


@app.post("/v1/chat/completions")
async def chat(req: ChatCompletionRequest):

    model = req.model or MODEL

    payload = {
        "model": model,
        "messages": [
            {
                "role": m.role,
                "content": m.content
            }
            for m in req.messages
        ],
        "stream": False
    }

    try:

        result = await call_ollama(payload)

        content = result["message"]["content"]

        return {
            "id": f"chatcmpl-{uuid.uuid4()}",
            "object": "chat.completion",
            "created": int(time.time()),
            "model": model,
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": content
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": 0,
                "completion_tokens": 0,
                "total_tokens": 0
            }
        }

    except Exception as ex:

        raise HTTPException(
            status_code=500,
            detail=str(ex)
        )