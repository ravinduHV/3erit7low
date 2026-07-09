from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.db.session import get_db
from src.db.models import User
from src.auth.dependencies import get_current_user
from src.progress.schemas import (
    SectionProgressSummary, PoolSelectionCreate, PoolSelectionResponse,
    StartProgressRequest, CompleteProgressRequest
)
from src.progress import service

router = APIRouter(prefix="/progress", tags=["Progress & Tracking"])

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
