from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date, datetime

class UserSyncRequest(BaseModel):
    token: str
    is_anonymous: bool = False
    full_name: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    email: str
    is_anonymous: bool
    display_name: Optional[str]
    full_name: Optional[str]
    date_of_birth: Optional[date]
    role: str
    section_id: Optional[str]
    registration_number: Optional[str]
    school_name: Optional[str]
    troop_number: Optional[str]
    district: Optional[str]
    province: Optional[str]
    joined_section_at: Optional[date]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
