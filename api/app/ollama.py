import httpx
import json
from fastapi import HTTPException
from app.config import OLLAMA_HOST, OLLAMA_MODEL

async def chat_completion(messages):
    url = f"{OLLAMA_HOST}/v1/chat/completions"

    async with httpx.AsyncClient(timeout=60) as client:
        async with client.stream(
            "POST",
            url,
            json={
                "model": OLLAMA_MODEL,
                "messages": messages,
                "stream": True,
                "options": {
                    "num_ctx": 2048,      # ◄ Caps context to prevent CPU segmentation faults
                    "num_predict": 512   # ◄ Limits how long a single reply can be
                }
            }
        ) as response:

            async for line in response.aiter_lines():

                if not line:
                    continue
                
                if not line.startswith("data: "):
                    continue

                if line.startswith("data: "):
                    line = line.removeprefix("data:").strip()

                if line == "[DONE]":
                    break

                data = json.loads(line)

                delta = data["choices"][0]["delta"]

                content = delta.get("content")

                if content:
                    yield content