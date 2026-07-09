from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.db.session import get_db
from src.auth.schemas import UserSyncRequest, UserResponse
from src.auth.service import decode_token, sync_user_data

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/sync", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def sync_user(
    request: UserSyncRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Decodes the Better Auth/Neon Auth token and registers or updates the user in the local database.
    This is called by the Flutter app right after a successful signup/login.
    """
    try:
        payload = decode_token(request.token)
        user_id = payload.get("sub")
        email = payload.get("email")
        
        if not user_id or not email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Token payload is missing user ID or email."
            )
            
        # Sync user data
        user = await sync_user_data(
            db=db,
            user_id=user_id,
            email=email,
            full_name=request.full_name,
            is_anonymous=request.is_anonymous
        )
        return user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
