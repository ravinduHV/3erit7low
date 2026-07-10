from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date

class PoolSelectionCreate(BaseModel):
    requirement_group_id: str
    requirement_id: str

class PoolSelectionResponse(BaseModel):
    id: str
    requirement_group_id: str
    requirement_id: str
    selected_at: datetime

    class Config:
        from_attributes = True

class RequirementProgressDetail(BaseModel):
    id: str
    name: str
    description: Optional[str]
    is_mandatory: bool
    evidence_required: bool
    min_age: Optional[float]
    max_age: Optional[float]
    min_service_months: Optional[int]
    status: str  # not_started | in_progress | completed
    started_at: Optional[date]
    completed_at: Optional[date]
    earliest_finish_date: Optional[date] = None
    notes: Optional[str]
    is_eligible: bool = True  # client-side helper based on age/service check
    reason_ineligible: Optional[str] = None

class RequirementGroupProgress(BaseModel):
    id: str
    name: str
    description: Optional[str]
    is_pool: bool
    min_select: int
    max_select: Optional[int]
    requirements: List[RequirementProgressDetail]
    selected_count: int = 0
    completed_count: int = 0

class AwardProgressDetail(BaseModel):
    id: str
    name: str
    description: Optional[str]
    badge_image_url: Optional[str]
    min_age: Optional[float]
    max_age: Optional[float]
    min_service_months: Optional[int]
    prerequisite_award_id: Optional[str] = None
    is_optional: bool = False
    groups: List[RequirementGroupProgress]
    percent_completed: float = 0.0
    is_completed: bool = False

class SectionProgressSummary(BaseModel):
    id: str
    name: str
    color_hex: str
    icon_name: Optional[str]
    awards: List[AwardProgressDetail]

class StartProgressRequest(BaseModel):
    started_at: Optional[date] = None

class CompleteProgressRequest(BaseModel):
    completed_at: Optional[date] = None

class RecommendationItem(BaseModel):
    award_id: str
    award_name: str
    status: str  # recommended | locked_prerequisite | locked_service | locked_age | completed
    reason: str
    target_completion_date: Optional[date] = None

class PredictionResponse(BaseModel):
    current_age: float
    remaining_days_in_section: int
    highest_achievable_award_id: Optional[str] = None
    highest_achievable_award_name: Optional[str] = None
    is_aging_out_warning: bool
    recommendations: List[RecommendationItem]
