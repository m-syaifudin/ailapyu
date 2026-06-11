import json
import asyncpg
from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from app.config import SYSTEM_PROMPT
from app.database import fetch_history, save_message
from app.ollama import chat_completion

router = APIRouter()

class ChatRequest(BaseModel):
    userId: str
    message: str

class ChatResponse(BaseModel):
    userId: str
    reply: str

@router.get("/health")
async def health():
    return {"status": "ok"}


@router.post("/chat")
async def chat(req: ChatRequest, request: Request):
    userId = req.userId
    
    pool: asyncpg.Pool = request.app.state.pool

    await save_message(pool, "user", req.message, userId)

    history = await fetch_history(pool, userId)

    messages = [{"role": "system", "content": SYSTEM_PROMPT}] + history 

    # reply = await chat_completion(messages)

    async def generate():
        full_reply = ""

        async for chunk in chat_completion(messages):
            full_reply += chunk
            yield chunk          

        await save_message(pool, "assistant", full_reply)

        # return ChatResponse(reply=reply)

    return StreamingResponse(
        generate(),
        media_type="text/plain"
    )