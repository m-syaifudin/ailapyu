import logging

import httpx
from fastapi import APIRouter, Depends, HTTPException

from core.config import Settings, get_settings
from core.dependencies import verify_api_key
from schemas.openai_compat import ModelCard, ModelList

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/v1/models", response_model=ModelList)
async def list_models(
    settings: Settings = Depends(get_settings),
    _: None = Depends(verify_api_key),
):
    """Return all models currently available in Ollama."""
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(f"{settings.ollama_base_url}/api/tags")
            resp.raise_for_status()
            data = resp.json()
    except httpx.RequestError as exc:
        logger.error("Ollama unreachable: %s", exc)
        raise HTTPException(status_code=503, detail=f"Ollama unreachable: {exc}")
    except httpx.HTTPStatusError as exc:
        raise HTTPException(
            status_code=exc.response.status_code, detail=exc.response.text
        )

    models = [ModelCard(id=m["name"]) for m in data.get("models", [])]
    return ModelList(data=models)