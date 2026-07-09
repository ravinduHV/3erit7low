from datetime import datetime
from typing import List, Optional, Type, TypeVar
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from src.db.base import Base
from src.db.models import Section, Award, RequirementGroup, Requirement
from src.admin.schemas import (
    SectionCreate, SectionUpdate,
    AwardCreate, AwardUpdate,
    RequirementGroupCreate, RequirementGroupUpdate,
    RequirementCreate, RequirementUpdate,
    ReorderRequest
)

T = TypeVar("T")

# Helper to fetch by ID
async def get_by_id(db: AsyncSession, model: Type[T], id_val: str) -> Optional[T]:
    result = await db.execute(select(model).where(model.id == id_val))
    return result.scalar_one_or_none()

# Helper to fetch all active
async def get_all(db: AsyncSession, model: Type[T], order_by_col: str, active_only: bool = False) -> List[T]:
    query = select(model)
    if active_only and hasattr(model, "is_active"):
        query = query.where(model.is_active == True)
    if hasattr(model, order_by_col):
        query = query.order_by(getattr(model, order_by_col))
    result = await db.execute(query)
    return list(result.scalars().all())


# ─── SECTIONS CRUD ─────────────────────────────────────────────
async def create_section(db: AsyncSession, data: SectionCreate) -> Section:
    section = Section(**data.model_dump())
    db.add(section)
    await db.flush()
    return section

async def update_section(db: AsyncSession, section: Section, data: SectionUpdate) -> Section:
    update_dict = data.model_dump(exclude_unset=True)
    for key, val in update_dict.items():
        setattr(section, key, val)
    section.updated_at = datetime.utcnow()
    await db.flush()
    return section

async def delete_section(db: AsyncSession, section: Section) -> None:
    await db.delete(section)
    await db.flush()


# ─── AWARDS CRUD ───────────────────────────────────────────────
async def create_award(db: AsyncSession, data: AwardCreate) -> Award:
    award = Award(**data.model_dump())
    db.add(award)
    await db.flush()
    return award

async def update_award(db: AsyncSession, award: Award, data: AwardUpdate) -> Award:
    update_dict = data.model_dump(exclude_unset=True)
    for key, val in update_dict.items():
        setattr(award, key, val)
    award.updated_at = datetime.utcnow()
    await db.flush()
    return award

async def delete_award(db: AsyncSession, award: Award) -> None:
    await db.delete(award)
    await db.flush()

async def get_section_awards(db: AsyncSession, section_id: str, active_only: bool = False) -> List[Award]:
    query = select(Award).where(Award.section_id == section_id)
    if active_only:
        query = query.where(Award.is_active == True)
    query = query.order_by(Award.display_order)
    result = await db.execute(query)
    return list(result.scalars().all())


# ─── REQUIREMENT GROUPS CRUD ───────────────────────────────────
async def create_requirement_group(db: AsyncSession, data: RequirementGroupCreate) -> RequirementGroup:
    group = RequirementGroup(**data.model_dump())
    db.add(group)
    await db.flush()
    return group

async def update_requirement_group(db: AsyncSession, group: RequirementGroup, data: RequirementGroupUpdate) -> RequirementGroup:
    update_dict = data.model_dump(exclude_unset=True)
    for key, val in update_dict.items():
        setattr(group, key, val)
    await db.flush()
    return group

async def delete_requirement_group(db: AsyncSession, group: RequirementGroup) -> None:
    await db.delete(group)
    await db.flush()

async def get_award_groups(db: AsyncSession, award_id: str, active_only: bool = False) -> List[RequirementGroup]:
    query = select(RequirementGroup).where(RequirementGroup.award_id == award_id)
    if active_only:
        query = query.where(RequirementGroup.is_active == True)
    query = query.order_by(RequirementGroup.display_order)
    result = await db.execute(query)
    return list(result.scalars().all())


# ─── REQUIREMENTS CRUD ─────────────────────────────────────────
async def create_requirement(db: AsyncSession, data: RequirementCreate) -> Requirement:
    requirement = Requirement(**data.model_dump())
    db.add(requirement)
    await db.flush()
    return requirement

async def update_requirement(db: AsyncSession, requirement: Requirement, data: RequirementUpdate) -> Requirement:
    update_dict = data.model_dump(exclude_unset=True)
    for key, val in update_dict.items():
        setattr(requirement, key, val)
    requirement.updated_at = datetime.utcnow()
    await db.flush()
    return requirement

async def delete_requirement(db: AsyncSession, requirement: Requirement) -> None:
    await db.delete(requirement)
    await db.flush()

async def get_group_requirements(db: AsyncSession, group_id: str, active_only: bool = False) -> List[Requirement]:
    query = select(Requirement).where(Requirement.group_id == group_id)
    if active_only:
        query = query.where(Requirement.is_active == True)
    query = query.order_by(Requirement.display_order)
    result = await db.execute(query)
    return list(result.scalars().all())


# ─── REORDER BULK UPDATE ──────────────────────────────────────
async def reorder_items(db: AsyncSession, model: Type[Base], reorder_data: ReorderRequest) -> None:
    for item in reorder_data.items:
        result = await db.execute(select(model).where(model.id == item.id))
        obj = result.scalar_one_or_none()
        if obj:
            obj.display_order = item.display_order
            if hasattr(obj, "updated_at"):
                obj.updated_at = datetime.utcnow()
    await db.flush()
