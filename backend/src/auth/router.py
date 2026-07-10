from typing import Dict, Any

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.db.session import get_db
from src.auth.dependencies import get_jwt_payload
from src.auth.schemas import UserSyncRequest, UserResponse
from src.auth.service import sync_user_data

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/sync", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def sync_user(
    request: UserSyncRequest,
    payload: Dict[str, Any] = Depends(get_jwt_payload),
    db: AsyncSession = Depends(get_db),
):
    """
    Upserts the authenticated Neon Auth user into the local app database.

    Called by Flutter immediately after sign-up or sign-in:
      1. Flutter signs in/up via Neon Auth → gets EdDSA JWT
      2. Flutter calls POST /v1/auth/sync with Authorization: Bearer <JWT>
      3. FastAPI validates the JWT (JWKS) → creates/updates the local user row
      4. Returns the full UserResponse for the app to store locally

    Uses get_jwt_payload (not get_current_user) so it works for brand-new
    users who don't yet have a row in the local users table.

    Identity mode and optional full_name are set here; change later via
    PATCH /v1/users/me/identity.
    """
    user = await sync_user_data(
        db=db,
        user_id=payload["sub"],
        email=payload.get("email", ""),
        full_name=request.full_name,
        is_anonymous=request.is_anonymous,
    )
    return user
