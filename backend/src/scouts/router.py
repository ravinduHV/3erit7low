from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.db.session import get_db
from src.db.models import User
from src.auth.dependencies import get_current_user
from src.auth.schemas import UserResponse
from src.scouts.schemas import UserProfileUpdate, IdentityModeUpdate
from src.scouts.service import update_user_profile, update_user_identity_mode

router = APIRouter(prefix="/users", tags=["Scouts & Profiles"])

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Retrieve the current logged-in user profile details."""
    return current_user

@router.patch("/me", response_model=UserResponse)
async def update_me(
    update_data: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Updates non-identifying profile configurations (e.g. section, DOB)."""
    updated_user = await update_user_profile(db, current_user, update_data)
    return updated_user

@router.patch("/me/identity", response_model=UserResponse)
async def update_my_identity(
    update_data: IdentityModeUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Toggles anonymity mode and handles profile name/school fields accordingly."""
    # Input validation: If known user is selected, full name is mandatory
    if not update_data.is_anonymous and not update_data.full_name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Full name is required for known users."
        )
        
    updated_user = await update_user_identity_mode(db, current_user, update_data)
    return updated_user
