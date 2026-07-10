from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date

# ─── SECTIONS ─────────────────────────────────────────────────
class SectionBase(BaseModel):
    name: str = Field(..., max_length=100)
    slug: str = Field(..., max_length=50)
    min_age: Optional[float] = None
    max_age: Optional[float] = None
    color_hex: str = Field(..., max_length=7)
    icon_name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = Field(None, max_length=1000)
    display_order: int = 0
    role_type: str = Field("scout", max_length=20) # scout | leader
    is_active: bool = True
    linked_section_id: Optional[str] = None  # predecessor section for cross-section service credit

class SectionCreate(SectionBase):
    id: str = Field(..., max_length=50)

class SectionUpdate(BaseModel):
    name: Optional[str] = None
    slug: Optional[str] = None
    min_age: Optional[float] = None
    max_age: Optional[float] = None
    color_hex: Optional[str] = None
    icon_name: Optional[str] = None
    description: Optional[str] = None
    display_order: Optional[int] = None
    role_type: Optional[str] = None
    is_active: Optional[bool] = None
    linked_section_id: Optional[str] = None

class SectionAdminResponse(SectionBase):
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ─── AWARDS ───────────────────────────────────────────────────
class AwardBase(BaseModel):
    name: str = Field(..., max_length=150)
    description: Optional[str] = Field(None, max_length=1000)
    badge_image_url: Optional[str] = Field(None, max_length=500)
    min_age: Optional[float] = None
    max_age: Optional[float] = None
    min_service_months: Optional[int] = None
    prerequisite_award_id: Optional[str] = None
    is_optional: bool = False
    # Engagement: can start this award N months after prerequisite was STARTED
    min_months_after_prereq_started: Optional[int] = None
    # If True: award start defaults to prerequisite completion date
    start_date_follows_prereq: bool = True
    display_order: int = 0
    is_active: bool = True

class AwardCreate(AwardBase):
    id: str = Field(..., max_length=50)
    section_id: str

class AwardUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    badge_image_url: Optional[str] = None
    min_age: Optional[float] = None
    max_age: Optional[float] = None
    min_service_months: Optional[int] = None
    prerequisite_award_id: Optional[str] = None
    is_optional: Optional[bool] = None
    min_months_after_prereq_started: Optional[int] = None
    start_date_follows_prereq: Optional[bool] = None
    display_order: Optional[int] = None
    is_active: Optional[bool] = None

class AwardAdminResponse(AwardBase):
    id: str
    section_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ─── REQUIREMENT GROUPS ───────────────────────────────────────
class RequirementGroupBase(BaseModel):
    name: str = Field(..., max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    is_pool: bool = False
    min_select: int = 1
    max_select: Optional[int] = 1
    display_order: int = 0
    is_active: bool = True

class RequirementGroupCreate(RequirementGroupBase):
    id: str = Field(..., max_length=50)
    award_id: str

class RequirementGroupUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    is_pool: Optional[bool] = None
    min_select: Optional[int] = None
    max_select: Optional[int] = None
    display_order: Optional[int] = None
    is_active: Optional[bool] = None

class RequirementGroupAdminResponse(RequirementGroupBase):
    id: str
    award_id: str

    class Config:
        from_attributes = True


# ─── REQUIREMENTS ─────────────────────────────────────────────
class RequirementBase(BaseModel):
    name: str = Field(..., max_length=300)
    description: Optional[str] = Field(None, max_length=2000)
    min_age: Optional[float] = None
    max_age: Optional[float] = None
    min_service_months: Optional[int] = None
    is_mandatory: bool = True
    evidence_required: bool = False
    evidence_notes: Optional[str] = Field(None, max_length=1000)
    reference_url: Optional[str] = Field(None, max_length=500)
    display_order: int = 0
    is_active: bool = True

class RequirementCreate(RequirementBase):
    id: str = Field(..., max_length=50)
    group_id: str

class RequirementUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    min_age: Optional[float] = None
    max_age: Optional[float] = None
    min_service_months: Optional[int] = None
    is_mandatory: Optional[bool] = None
    evidence_required: Optional[bool] = None
    evidence_notes: Optional[str] = None
    reference_url: Optional[str] = None
    display_order: Optional[int] = None
    is_active: Optional[bool] = None

class RequirementAdminResponse(RequirementBase):
    id: str
    group_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ─── REORDER REQUEST ──────────────────────────────────────────
class ReorderItem(BaseModel):
    id: str
    display_order: int

class ReorderRequest(BaseModel):
    items: List[ReorderItem]
