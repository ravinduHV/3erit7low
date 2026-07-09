from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.db.session import get_db
from src.db.models import User
from src.auth.dependencies import get_current_user
from src.progress.service import get_scout_progress_summary
from src.assistant.schemas import AssistantResponse
from src.assistant.engine import generate_suggestions

router = APIRouter(prefix="/assistant", tags=["Personal Assistant"])

@router.get("/suggestions", response_model=AssistantResponse)
async def get_suggestions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieves personal rule-based suggestions and tips based on the user's progress and age."""
    summary = await get_scout_progress_summary(db, current_user)
    if not summary:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User has not initialized their profile/onboarding yet."
        )
        
    suggestions = generate_suggestions(
        summary=summary,
        dob=current_user.date_of_birth,
        joined_at=current_user.joined_section_at
    )
    return AssistantResponse(suggestions=suggestions)
