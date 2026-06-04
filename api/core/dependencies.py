from fastapi import Depends, Header, HTTPException

from .config import Settings, get_settings


async def verify_api_key(
    authorization: str = Header(default=None),
    settings: Settings = Depends(get_settings),
) -> None:
    """
    Optional API-key guard.
    Skipped entirely when API_KEY is blank in .env.
    Clients must send:  Authorization: Bearer <key>
    """
    if not settings.api_key:
        return  # auth disabled

    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Missing or malformed Authorization header. Expected: Bearer <key>",
        )

    token = authorization.removeprefix("Bearer ").strip()
    if token != settings.api_key:
        raise HTTPException(status_code=401, detail="Invalid API key")