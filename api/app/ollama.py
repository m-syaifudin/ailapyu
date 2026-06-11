import httpx
import json
from fastapi import HTTPException
from app.config import OLLAMA_HOST, OLLAMA_MODEL


# async def chat_completion(messages: list[dict]) -> str:
#     url = f"{OLLAMA_HOST}/v1/chat/completions"
#     try:
#         async with httpx.AsyncClient(timeout=120.0) as client:
#             resp = await client.post(
#                 url,
#                 json={"model": OLLAMA_MODEL, "messages": messages},
#             )
#             resp.raise_for_status()
#     except httpx.HTTPError as exc:
#         raise HTTPException(status_code=502, detail=f"Ollama error: {exc}")

#     return resp.json()["choices"][0]["message"]["content"]

async def chat_completion(messages):
    url = f"{OLLAMA_HOST}/v1/chat/completions"

    async with httpx.AsyncClient(timeout=None) as client:
        async with client.stream(
            "POST",
            url,
            json={
                "model": OLLAMA_MODEL,
                "messages": messages,
                "stream": True
                "options": {
                    "num_ctx": 2048,      # ◄ Caps context to prevent CPU segmentation faults
                    "num_predict": 512,    # ◄ Limits how long a single reply can be
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