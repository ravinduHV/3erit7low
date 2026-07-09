from pydantic import BaseModel
from typing import Optional
from datetime import date

class UserProfileUpdate(BaseModel):
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    profile_image_url: Optional[str] = None
    section_id: Optional[str] = None
    joined_section_at: Optional[date] = None

class IdentityModeUpdate(BaseModel):
    is_anonymous: bool
    full_name: Optional[str] = None
    school_name: Optional[str] = None
    troop_number: Optional[str] = None
    district: Optional[str] = None
    province: Optional[str] = None
    registration_number: Optional[str] = None
