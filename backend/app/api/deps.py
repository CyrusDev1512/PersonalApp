"""Dependency dùng chung: xác thực bearer token, session DB."""

from __future__ import annotations

import hmac

from fastapi import Header, HTTPException, status

from app.config import get_settings


def require_token(authorization: str | None = Header(default=None)) -> None:
    expected = get_settings().app_token
    if not authorization or not expected:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Unauthorized")
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Unauthorized")
    if not hmac.compare_digest(token.strip().encode("utf-8"), expected.encode("utf-8")):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Unauthorized")
