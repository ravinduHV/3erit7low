from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime


class UserSyncRequest(BaseModel):
    """
    Body for POST /v1/auth/sync.
    Called by Flutter right after sign-up or sign-in to register the user
    in the local app database. The JWT is provided in the Authorization header
    (not in the body) — it is validated by get_current_user before this runs.
    """
    is_anonymous: bool = False
    full_name: Optional[str] = None  # Required for known-mode; ignored for anonymous


class UserResponse(BaseModel):
    """Full user profile returned by sync, GET /me, and PATCH /me."""
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
