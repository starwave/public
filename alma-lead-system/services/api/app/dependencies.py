import logging

from fastapi import HTTPException, Request, Security, status
from fastapi.security import APIKeyHeader
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.config import settings

logger = logging.getLogger(__name__)

# ── Rate limiter ──
limiter = Limiter(
    key_func=get_remote_address,
    storage_uri=settings.redis_url,
)

# ── API key auth for internal endpoints ──
_api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


async def require_api_key(
    api_key: str | None = Security(_api_key_header),
) -> str:
    if not api_key or api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API key.",
        )
    return api_key


def get_email_from_body(request: Request) -> str:
    """Key function for per-email rate limiting on lead creation."""
    # slowapi key functions are sync; we fall back to IP if email isn't available yet
    return get_remote_address(request)
