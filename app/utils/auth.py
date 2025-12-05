import os

from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader

# Header name used for API key verification
API_KEY_HEADER = "x-api-key"
_API_KEY = os.getenv("API_KEY")
_api_key_header = APIKeyHeader(name=API_KEY_HEADER, auto_error=False)


def require_api_key(api_key: str = Security(_api_key_header)) -> None:
    """
    Enforce API key checks for protected routes.
    If API_KEY is not set, the dependency becomes a no-op to keep local dev frictionless.
    """
    if not _API_KEY:
        return

    if api_key == _API_KEY:
        return

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or missing API key",
    )
