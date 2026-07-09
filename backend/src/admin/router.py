from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from src.db.session import get_db
from src.db.models import Section, Award, RequirementGroup, Requirement
from src.auth.dependencies import get_current_admin
from src.admin.schemas import (
    SectionCreate, SectionUpdate, SectionAdminResponse,
    AwardCreate, AwardUpdate, AwardAdminResponse,
    RequirementGroupCreate, RequirementGroupUpdate, RequirementGroupAdminResponse,
    RequirementCreate, RequirementUpdate, RequirementAdminResponse,
    ReorderRequest
)
from src.admin import service

router = APIRouter(prefix="/admin", tags=["Admin & Syllabus CRUD"])

# ─── SECTIONS CRUD ─────────────────────────────────────────────

@router.get("/sections", response_model=List[SectionAdminResponse])
async def get_sections(
    active_only: bool = False,
    db: AsyncSession = Depends(get_db)
):
    """Retrieve all sections ordered by display_order. Unrestricted read access."""
    return await service.get_all(db, Section, order_by_col="display_order", active_only=active_only)

@router.get("/sections/{id}", response_model=SectionAdminResponse)
async def get_section(
    id: str,
    db: AsyncSession = Depends(get_db)
):
    """Retrieve a single section by ID."""
    section = await service.get_by_id(db, Section, id)
    if not section:
        raise HTTPException(status_code=404, detail="Section not found")
    return section

@router.post("/sections", response_model=SectionAdminResponse, status_code=status.HTTP_201_CREATED)
async def create_section(
    data: SectionCreate,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Create a new section (Admin only)."""
    existing = await service.get_by_id(db, Section, data.id)
    if existing:
        raise HTTPException(status_code=400, detail="Section with this ID already exists")
    return await service.create_section(db, data)

@router.patch("/sections/{id}", response_model=SectionAdminResponse)
async def update_section(
    id: str,
    data: SectionUpdate,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update section configurations (Admin only)."""
    section = await service.get_by_id(db, Section, id)
    if not section:
        raise HTTPException(status_code=404, detail="Section not found")
    return await service.update_section(db, section, data)

@router.delete("/sections/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_section(
    id: str,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete a section (Admin only)."""
    section = await service.get_by_id(db, Section, id)
    if not section:
        raise HTTPException(status_code=404, detail="Section not found")
    await service.delete_section(db, section)

@router.put("/sections/reorder", status_code=status.HTTP_204_NO_CONTENT)
async def reorder_sections(
    data: ReorderRequest,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Reorder display_order for sections bulk update (Admin only)."""
    await service.reorder_items(db, Section, data)


# ─── AWARDS CRUD ───────────────────────────────────────────────

@router.get("/sections/{section_id}/awards", response_model=List[AwardAdminResponse])
async def get_section_awards(
    section_id: str,
    active_only: bool = False,
    db: AsyncSession = Depends(get_db)
):
    """List awards within a specific section."""
    return await service.get_section_awards(db, section_id, active_only)

@router.get("/awards/{id}", response_model=AwardAdminResponse)
async def get_award(
    id: str,
    db: AsyncSession = Depends(get_db)
):
    """Retrieve a single award."""
    award = await service.get_by_id(db, Award, id)
    if not award:
        raise HTTPException(status_code=404, detail="Award not found")
    return award

@router.post("/awards", response_model=AwardAdminResponse, status_code=status.HTTP_201_CREATED)
async def create_award(
    data: AwardCreate,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Create an award (Admin only)."""
    section = await service.get_by_id(db, Section, data.section_id)
    if not section:
        raise HTTPException(status_code=404, detail="Target section not found")
    existing = await service.get_by_id(db, Award, data.id)
    if existing:
        raise HTTPException(status_code=400, detail="Award with this ID already exists")
    return await service.create_award(db, data)

@router.patch("/awards/{id}", response_model=AwardAdminResponse)
async def update_award(
    id: str,
    data: AwardUpdate,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update award attributes (Admin only)."""
    award = await service.get_by_id(db, Award, id)
    if not award:
        raise HTTPException(status_code=404, detail="Award not found")
    return await service.update_award(db, award, data)

@router.delete("/awards/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_award(
    id: str,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete an award (Admin only)."""
    award = await service.get_by_id(db, Award, id)
    if not award:
        raise HTTPException(status_code=404, detail="Award not found")
    await service.delete_award(db, award)

@router.put("/awards/reorder", status_code=status.HTTP_204_NO_CONTENT)
async def reorder_awards(
    data: ReorderRequest,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Reorder display_order for awards (Admin only)."""
    await service.reorder_items(db, Award, data)


# ─── REQUIREMENT GROUPS CRUD ───────────────────────────────────

@router.get("/awards/{award_id}/groups", response_model=List[RequirementGroupAdminResponse])
async def get_award_groups(
    award_id: str,
    active_only: bool = False,
    db: AsyncSession = Depends(get_db)
):
    """Get requirement groups inside an award."""
    return await service.get_award_groups(db, award_id, active_only)

@router.get("/groups/{id}", response_model=RequirementGroupAdminResponse)
async def get_group(
    id: str,
    db: AsyncSession = Depends(get_db)
):
    """Retrieve a single requirement group."""
    group = await service.get_by_id(db, RequirementGroup, id)
    if not group:
        raise HTTPException(status_code=404, detail="Requirement group not found")
    return group

@router.post("/groups", response_model=RequirementGroupAdminResponse, status_code=status.HTTP_201_CREATED)
async def create_group(
    data: RequirementGroupCreate,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Create a requirement group (Admin only)."""
    award = await service.get_by_id(db, Award, data.award_id)
    if not award:
        raise HTTPException(status_code=404, detail="Target award not found")
    existing = await service.get_by_id(db, RequirementGroup, data.id)
    if existing:
        raise HTTPException(status_code=400, detail="Group with this ID already exists")
    return await service.create_requirement_group(db, data)

@router.patch("/groups/{id}", response_model=RequirementGroupAdminResponse)
async def update_group(
    id: str,
    data: RequirementGroupUpdate,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update requirement group details (Admin only)."""
    group = await service.get_by_id(db, RequirementGroup, id)
    if not group:
        raise HTTPException(status_code=404, detail="Requirement group not found")
    return await service.update_requirement_group(db, group, data)

@router.delete("/groups/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_group(
    id: str,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete a requirement group (Admin only)."""
    group = await service.get_by_id(db, RequirementGroup, id)
    if not group:
        raise HTTPException(status_code=404, detail="Requirement group not found")
    await service.delete_requirement_group(db, group)

@router.put("/groups/reorder", status_code=status.HTTP_204_NO_CONTENT)
async def reorder_groups(
    data: ReorderRequest,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Reorder display_order for requirement groups (Admin only)."""
    await service.reorder_items(db, RequirementGroup, data)


# ─── REQUIREMENTS CRUD ─────────────────────────────────────────

@router.get("/groups/{group_id}/requirements", response_model=List[RequirementAdminResponse])
async def get_group_requirements(
    group_id: str,
    active_only: bool = False,
    db: AsyncSession = Depends(get_db)
):
    """Retrieve all requirements within a group."""
    return await service.get_group_requirements(db, group_id, active_only)

@router.get("/requirements/{id}", response_model=RequirementAdminResponse)
async def get_requirement(
    id: str,
    db: AsyncSession = Depends(get_db)
):
    """Retrieve a single requirement."""
    req = await service.get_by_id(db, Requirement, id)
    if not req:
        raise HTTPException(status_code=404, detail="Requirement not found")
    return req

@router.post("/requirements", response_model=RequirementAdminResponse, status_code=status.HTTP_201_CREATED)
async def create_requirement(
    data: RequirementCreate,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Create a requirement (Admin only)."""
    group = await service.get_by_id(db, RequirementGroup, data.group_id)
    if not group:
        raise HTTPException(status_code=404, detail="Target requirement group not found")
    existing = await service.get_by_id(db, Requirement, data.id)
    if existing:
        raise HTTPException(status_code=400, detail="Requirement with this ID already exists")
    return await service.create_requirement(db, data)

@router.patch("/requirements/{id}", response_model=RequirementAdminResponse)
async def update_requirement(
    id: str,
    data: RequirementUpdate,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update requirement parameters (Admin only)."""
    req = await service.get_by_id(db, Requirement, id)
    if not req:
        raise HTTPException(status_code=404, detail="Requirement not found")
    return await service.update_requirement(db, req, data)

@router.delete("/requirements/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_requirement(
    id: str,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete a requirement (Admin only)."""
    req = await service.get_by_id(db, Requirement, id)
    if not req:
        raise HTTPException(status_code=404, detail="Requirement not found")
    await service.delete_requirement(db, req)

@router.put("/requirements/reorder", status_code=status.HTTP_204_NO_CONTENT)
async def reorder_requirements(
    data: ReorderRequest,
    admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Reorder display_order for requirements (Admin only)."""
    await service.reorder_items(db, Requirement, data)
