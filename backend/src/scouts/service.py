from datetime import datetime
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from src.db.models import User
from src.scouts.schemas import UserProfileUpdate, IdentityModeUpdate

async def update_user_profile(
    db: AsyncSession,
    user: User,
    update_data: UserProfileUpdate
) -> User:
    """Updates general profile data for the current user."""
    if update_data.date_of_birth is not None:
        user.date_of_birth = update_data.date_of_birth
    if update_data.gender is not None:
        user.gender = update_data.gender
    if update_data.profile_image_url is not None:
        user.profile_image_url = update_data.profile_image_url
    if update_data.section_id is not None:
        user.section_id = update_data.section_id
    if update_data.joined_section_at is not None:
        user.joined_section_at = update_data.joined_section_at

    user.updated_at = datetime.utcnow()
    await db.flush()
    return user

async def update_user_identity_mode(
    db: AsyncSession,
    user: User,
    update_data: IdentityModeUpdate
) -> User:
    """Toggles anonymous/known status and updates identity fields accordingly."""
    user.is_anonymous = update_data.is_anonymous
    
    if update_data.is_anonymous:
        # Clear private data
        user.full_name = None
        user.school_name = None
        user.troop_number = None
        user.district = None
        user.province = None
        user.registration_number = None
        
        # Generate anonymous display name if not already set correctly
        short_id = user.id[:4].upper()
        user.display_name = f"Scout #{short_id}"
    else:
        # Update known data fields
        user.full_name = update_data.full_name
        user.school_name = update_data.school_name
        user.troop_number = update_data.troop_number
        user.district = update_data.district
        user.province = update_data.province
        user.registration_number = update_data.registration_number
        
        # Set display name to full name
        user.display_name = update_data.full_name or user.email.split("@")[0]

    user.updated_at = datetime.utcnow()
    await db.flush()
    return user
