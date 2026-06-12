import json
import asyncpg
import asyncio
from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from app.config import SYSTEM_PROMPT
from app.database import fetch_history, save_message
from app.ollama import chat_completion
from app.routers import check_prompt_guardrails

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
    await check_prompt_guardrails(req.message)
    
    pool: asyncpg.Pool = request.app.state.pool

    await save_message(pool, "user", req.message, req.userId)

    history = await fetch_history(pool, req.userId)
    messages = [{"role": "system", "content": SYSTEM_PROMPT}] + history 

    # reply = await chat_completion(messages)

    async def generate():
        full_reply = ""

        try:
            async for chunk in chat_completion(messages):
                if await request.is_disconnected():
                    raise asyncio.CancelledError()
                    
                full_reply += chunk
                yield chunk          

            await save_message(pool, "assistant", full_reply, req.userId)

            # return ChatResponse(reply=reply)

        except asyncio.CancelledError:
            print(f"Chat interrupted by user {req.userId}. Assistant response discarded.")
            raise    

        except Exception as e:
            print(f"An unexpected error occurred: {e}")
            raise

    return StreamingResponse(
        generate(),
        media_type="text/plain"
    )