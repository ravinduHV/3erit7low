from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.db.session import get_db
from src.db.models import User
from src.auth.dependencies import get_current_user
from src.progress.schemas import (
    SectionProgressSummary, PoolSelectionCreate, PoolSelectionResponse,
    StartProgressRequest, CompleteProgressRequest, PredictionResponse,
    AwardDateUpdate, AwardCompleteRequest
)
from src.progress import service
from src.progress import prediction_service

router = APIRouter(prefix="/progress", tags=["Progress & Tracking"])

@router.get("/predictions", response_model=PredictionResponse)
async def get_predictions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate path recommendations and highest award forecast for the active scout."""
    res = await prediction_service.get_progress_predictions(db, current_user)
    if not res:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User has not set an active section yet. Complete onboarding first."
        )
    return res

@router.get("/summary", response_model=SectionProgressSummary)
async def get_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieves progress summary of all awards/requirements for the scout's active section."""
    summary = await service.get_scout_progress_summary(db, current_user)
    if not summary:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User has not set an active section yet. Complete onboarding first."
        )
    return summary

@router.post("/requirements/{req_id}/start", status_code=status.HTTP_200_OK)
async def start_requirement(
    req_id: str,
    req_body: Optional[StartProgressRequest] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Mark a requirement as in-progress."""
    started_at = req_body.started_at if req_body else None
    await service.start_requirement_progress(db, current_user.id, req_id, started_at)
    return {"message": "Requirement marked as in-progress"}

@router.post("/requirements/{req_id}/complete", status_code=status.HTTP_200_OK)
async def complete_requirement(
    req_id: str,
    req_body: Optional[CompleteProgressRequest] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Mark a requirement as completed."""
    completed_at = req_body.completed_at if req_body else None
    await service.complete_requirement_progress(db, current_user.id, req_id, completed_at)
    return {"message": "Requirement marked as completed"}


@router.delete("/requirements/{req_id}", status_code=status.HTTP_200_OK)
async def reset_requirement(
    req_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Reset/delete progress for a requirement."""
    await service.delete_requirement_progress(db, current_user.id, req_id)
    return {"message": "Requirement progress reset"}


@router.post("/awards/{award_id}/complete", status_code=status.HTTP_200_OK)
async def complete_award(
    award_id: str,
    req_body: Optional[AwardCompleteRequest] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Mark an award as completed (with optional backdated date).
    If propagate_to_parents=True (default), also auto-completes uncompleted prerequisite
    awards up the entire prerequisite chain, each dated one day before the next.
    """
    completed_at = req_body.completed_at if req_body else None
    propagate = req_body.propagate_to_parents if req_body else True
    completed_ids = await service.complete_award_with_propagation(
        db, current_user.id, award_id, completed_at, propagate
    )
    await db.commit()
    return {"message": "Award marked as completed", "completed_award_ids": completed_ids}


@router.patch("/awards/{award_id}/dates", status_code=status.HTTP_200_OK)
async def update_award_dates(
    award_id: str,
    req_body: AwardDateUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Member-controlled: update the start and/or completion date of an award record.
    The prediction engine will automatically use these dates when recalculating forecasts.
    """
    await service.update_award_dates(
        db, current_user.id, award_id, req_body.started_at, req_body.completed_at
    )
    await db.commit()
    return {"message": "Award dates updated"}


@router.post("/pool-selections", response_model=PoolSelectionResponse, status_code=status.HTTP_201_CREATED)
async def make_pool_selection(
    selection: PoolSelectionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Save a scout's pool requirement choice."""
    try:
        res = await service.save_pool_selection(
            db,
            current_user.id,
            selection.requirement_group_id,
            selection.requirement_id
        )
        return res
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.delete("/pool-selections/{group_id}/{req_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_pool_selection(
    group_id: str,
    req_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a pool requirement choice (also resets progress)."""
    await service.remove_pool_selection(db, current_user.id, group_id, req_id)
