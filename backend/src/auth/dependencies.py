from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any

from src.db.session import get_db
from src.db.models import User
from src.auth.service import decode_token, get_user_by_id

# HTTPBearer extracts the token from "Authorization: Bearer <token>" header.
# auto_error=False lets us return a clean 401 instead of FastAPI's default error.
bearer_scheme = HTTPBearer(auto_error=False)


async def get_jwt_payload(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> Dict[str, Any]:
    """
    Validates the Neon Auth Bearer JWT and returns the decoded payload.
    Does NOT require the user to exist in the local database.

    Used by /sync (which creates the user) and any endpoint that only
    needs the JWT claims rather than the full local User object.
    """
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated. Provide 'Authorization: Bearer <token>'",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        payload = decode_token(credentials.credentials)
        if not payload.get("sub"):
            raise ValueError("Token is missing the 'sub' (user ID) claim")
        return payload
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    FastAPI dependency — validates the Neon Auth Bearer JWT and returns the local User.

    Flow:
      1. Extracts the JWT from 'Authorization: Bearer <token>'
      2. Verifies the RS256 signature using Neon Auth's JWKS public key
      3. Looks up the user in the local app database by the 'sub' claim (Neon Auth UUID)
      4. Returns the User ORM instance for use in route handlers

    Raises 401 if the token is missing, expired, or invalid.
    Raises 401 if the user has not been synced yet (call POST /v1/auth/sync first).
    Raises 403 if the user account is inactive.
    """
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated. Provide 'Authorization: Bearer <token>'",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        payload = decode_token(credentials.credentials)
        user_id: str = payload.get("sub")
        if not user_id:
            raise ValueError("Token is missing the 'sub' (user ID) claim")
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found in app database. Call POST /v1/auth/sync first.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been deactivated.",
        )

    return user


async def get_current_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    """Dependency that enforces the 'admin' role."""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin role required.",
        )
    return current_user


async def get_current_leader_or_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    """Dependency that enforces the 'leader' or 'admin' role."""
    if current_user.role not in ("leader", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Scout Leader or Admin role required.",
        )
    return current_user
