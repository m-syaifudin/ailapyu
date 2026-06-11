import httpx
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
            }
        ) as response:

            async for line in response.aiter_lines():
                if not line:
                    continue

                data = json.loads(line)

                if "message" in data:
                    content = data["message"]["content"]
                    yield content