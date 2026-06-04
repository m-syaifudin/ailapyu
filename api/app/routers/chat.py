import asyncpg
from fastapi import APIRouter, Request
from pydantic import BaseModel

from app.config import SYSTEM_PROMPT
from app.database import fetch_history, save_message
from app.ollama import chat_completion

router = APIRouter()


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    reply: str


@router.get("/health")
async def health():
    return {"status": "ok"}


@router.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest, request: Request):
    pool: asyncpg.Pool = request.app.state.pool

    await save_message(pool, "user", req.message)

    history = await fetch_history(pool)

    messages = [{"role": "system", "content": SYSTEM_PROMPT}] + history

    # Log the complete array as a clean JSON block
    logger.info(
        "Sending conversation payload to Llama:\n%s",
        json.dumps(messages, indent=2),
    )

    reply = await chat_completion(messages)

    await save_message(pool, "assistant", reply)

    return ChatResponse(reply=reply)