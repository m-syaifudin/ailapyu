from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from openai import AsyncOpenAI
import os

app = FastAPI(title="ailapyu API")

client = AsyncOpenAI(
    base_url=os.getenv("OLLAMA_BASE_URL", "http://ollama:11434/v1"),
    api_key="ollama",  # required by openai client, not used by Ollama
)

MODEL = os.getenv("OLLAMA_MODEL", "qwen2.5:1.5b")


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    reply: str


@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="message must not be empty")

    response = await client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": req.message}],
    )

    reply = response.choices[0].message.content
    return ChatResponse(reply=reply)


@app.get("/health")
async def health():
    return {"status": "ok"}