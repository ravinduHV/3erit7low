import calendar
from datetime import date, datetime
from typing import List, Optional, Tuple, Dict
from uuid import uuid4
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import delete
from src.db.models import User, Section, Award, RequirementGroup, Requirement, ScoutProgress, RequirementPoolSelection, ScoutAward
from src.progress.schemas import (
    RequirementProgressDetail, RequirementGroupProgress, AwardProgressDetail, SectionProgressSummary
)

def add_months(source_date: date, months: int) -> date:
    """Helper to add calendar months to a date."""
    month = source_date.month - 1 + months
    year = source_date.year + month // 12
    month = month % 12 + 1
    day = min(source_date.day, calendar.monthrange(year, month)[1])
    return date(year, month, day)

def calculate_age(dob: Optional[date]) -> float:
    """Calculates decimal age in years from DOB."""
    if not dob:
        return 0.0
    today = date.today()
    years = today.year - dob.year
    # Adjust for month/day
    months = today.month - dob.month
    days = today.day - dob.day
    return years + (months / 12.0) + (days / 365.0)

def calculate_service_months(joined_at: Optional[date]) -> int:
    """Calculates number of months since joining the section."""
    if not joined_at:
        return 0
    today = date.today()
    return (today.year - joined_at.year) * 12 + today.month - joined_at.month

def check_eligibility(
    req: Requirement,
    age: float,
    service_months: int
) -> Tuple[bool, Optional[str]]:
    """Checks if a scout is eligible for a requirement based on age and service."""
    if req.min_age is not None and age < float(req.min_age):
        return False, f"Minimum age required: {req.min_age} years (Current: {age:.1f})"
    if req.max_age is not None and age > float(req.max_age):
        return False, f"Maximum age limit exceeded: {req.max_age} years (Current: {age:.1f})"
    if req.min_service_months is not None and service_months < req.min_service_months:
        return False, f"Minimum service required: {req.min_service_months} months (Current: {service_months})"
    return True, None


# ─── PROGRESS MUTATIONS ────────────────────────────────────────

async def ensure_scout_award_started(
    db: AsyncSession,
    user_id: str,
    req_id: str,
    started_at_date: date
) -> None:
    """Ensures a ScoutAward progress entry exists and is marked as started."""
    # Find award linked to requirement
    award_res = await db.execute(
        select(Award)
        .join(RequirementGroup, RequirementGroup.award_id == Award.id)
        .join(Requirement, Requirement.group_id == RequirementGroup.id)
        .where(Requirement.id == req_id)
    )
    award = award_res.scalar_one_or_none()
    if not award:
        return
        
    sa_res = await db.execute(
        select(ScoutAward).where(
            ScoutAward.user_id == user_id,
            ScoutAward.award_id == award.id
        )
    )
    scout_award = sa_res.scalar_one_or_none()
    
    if not scout_award:
        scout_award = ScoutAward(
            id=str(uuid4()),
            user_id=user_id,
            award_id=award.id,
            started_at=started_at_date
        )
        db.add(scout_award)
        await db.flush()

async def start_requirement_progress(
    db: AsyncSession,
    user_id: str,
    req_id: str,
    started_at: Optional[date] = None
) -> ScoutProgress:
    """Marks a requirement as in_progress for a scout."""
    start_date = started_at or date.today()
    result = await db.execute(
        select(ScoutProgress).where(
            ScoutProgress.user_id == user_id,
            ScoutProgress.requirement_id == req_id
        )
    )
    progress = result.scalar_one_or_none()
    
    if progress:
        if progress.status == "not_started":
            progress.status = "in_progress"
            progress.started_at = start_date
            progress.updated_at = datetime.utcnow()
    else:
        progress = ScoutProgress(
            id=str(uuid4()),
            user_id=user_id,
            requirement_id=req_id,
            status="in_progress",
            started_at=start_date,
            updated_at=datetime.utcnow()
        )
        db.add(progress)
        
    await db.flush()
    # Ensure parent award is marked as started
    await ensure_scout_award_started(db, user_id, req_id, start_date)
    return progress

async def complete_requirement_progress(
    db: AsyncSession,
    user_id: str,
    req_id: str,
    completed_at: Optional[date] = None
) -> ScoutProgress:
    """Marks a requirement as completed for a scout."""
    comp_date = completed_at or date.today()
    result = await db.execute(
        select(ScoutProgress).where(
            ScoutProgress.user_id == user_id,
            ScoutProgress.requirement_id == req_id
        )
    )
    progress = result.scalar_one_or_none()
    
    if progress:
        progress.status = "completed"
        if not progress.started_at:
            progress.started_at = comp_date
        progress.completed_at = comp_date
        progress.updated_at = datetime.utcnow()
    else:
        progress = ScoutProgress(
            id=str(uuid4()),
            user_id=user_id,
            requirement_id=req_id,
            status="completed",
            started_at=comp_date,
            completed_at=comp_date,
            updated_at=datetime.utcnow()
        )
        db.add(progress)
        
    await db.flush()
    # Check if this completion triggers award completion
    await evaluate_award_completions(db, user_id, req_id, comp_date)
    return progress


# ─── POOL SELECTIONS ──────────────────────────────────────────

async def save_pool_selection(
    db: AsyncSession,
    user_id: str,
    group_id: str,
    req_id: str
) -> RequirementPoolSelection:
    """Saves a pool requirement selection for a scout after validating pool limits."""
    # Check if selection already exists
    exist_res = await db.execute(
        select(RequirementPoolSelection).where(
            RequirementPoolSelection.user_id == user_id,
            RequirementPoolSelection.requirement_group_id == group_id,
            RequirementPoolSelection.requirement_id == req_id
        )
    )
    existing = exist_res.scalar_one_or_none()
    if existing:
        return existing
        
    # Check pool limits
    group_res = await db.execute(select(RequirementGroup).where(RequirementGroup.id == group_id))
    group = group_res.scalar_one_or_none()
    if not group or not group.is_pool:
        raise ValueError("Target group is not a selectable pool")
        
    if group.max_select is not None:
        count_res = await db.execute(
            select(RequirementPoolSelection).where(
                RequirementPoolSelection.user_id == user_id,
                RequirementPoolSelection.requirement_group_id == group_id
            )
        )
        current_selections = len(count_res.scalars().all())
        if current_selections >= group.max_select:
            raise ValueError(f"Maximum selections limit of {group.max_select} reached for this pool")
            
    selection = RequirementPoolSelection(
        id=str(uuid4()),
        user_id=user_id,
        requirement_group_id=group_id,
        requirement_id=req_id,
        selected_at=datetime.utcnow()
    )
    db.add(selection)
    await db.flush()
    return selection

async def remove_pool_selection(
    db: AsyncSession,
    user_id: str,
    group_id: str,
    req_id: str
) -> None:
    """Removes a pool selection, and also clears any progress on that requirement."""
    await db.execute(
        delete(RequirementPoolSelection).where(
            RequirementPoolSelection.user_id == user_id,
            RequirementPoolSelection.requirement_group_id == group_id,
            RequirementPoolSelection.requirement_id == req_id
        )
    )
    # Also delete associated progress
    await db.execute(
        delete(ScoutProgress).where(
            ScoutProgress.user_id == user_id,
            ScoutProgress.requirement_id == req_id
        )
    )
    await db.flush()


# ─── PROGRESS SUMMARY CALCULATOR ────────────────────────────────

async def get_scout_progress_summary(
    db: AsyncSession,
    user: User
) -> Optional[SectionProgressSummary]:
    """Calculates progress details for the user's active section."""
    if not user.section_id:
        return None
        
    section_res = await db.execute(select(Section).where(Section.id == user.section_id))
    section = section_res.scalar_one_or_none()
    if not section:
        return None
        
    # Fetch all awards for the section
    awards_res = await db.execute(
        select(Award)
        .where(Award.section_id == section.id, Award.is_active == True)
        .order_by(Award.display_order)
    )
    awards = awards_res.scalars().all()
    
    # Fetch all progress records for the user
    progress_res = await db.execute(select(ScoutProgress).where(ScoutProgress.user_id == user.id))
    progress_map: Dict[str, ScoutProgress] = {p.requirement_id: p for p in progress_res.scalars().all()}
    
    # Fetch pool selections for the user
    pool_res = await db.execute(select(RequirementPoolSelection).where(RequirementPoolSelection.user_id == user.id))
    pool_selections = pool_res.scalars().all()
    selected_req_ids = {ps.requirement_id for ps in pool_selections}
    group_selections: Dict[str, int] = {}
    for ps in pool_selections:
        group_selections[ps.requirement_group_id] = group_selections.get(ps.requirement_group_id, 0) + 1

    # Fetch scout awards to get award started_at dates
    sa_res = await db.execute(select(ScoutAward).where(ScoutAward.user_id == user.id))
    scout_awards_map = {sa.award_id: sa for sa in sa_res.scalars().all()}
        
    # User traits for eligibility checks
    age = calculate_age(user.date_of_birth)
    
    awards_progress = []
    
    for award in awards:
        scout_award = scout_awards_map.get(award.id)
        award_start_date = scout_award.started_at if scout_award else None

        # Get requirement groups
        groups_res = await db.execute(
            select(RequirementGroup)
            .where(RequirementGroup.award_id == award.id, RequirementGroup.is_active == True)
            .order_by(RequirementGroup.display_order)
        )
        groups = groups_res.scalars().all()
        
        award_groups_progress = []
        total_reqs = 0
        completed_reqs = 0
        
        for group in groups:
            reqs_res = await db.execute(
                select(Requirement)
                .where(Requirement.group_id == group.id, Requirement.is_active == True)
                .order_by(Requirement.display_order)
            )
            reqs = reqs_res.scalars().all()
            
            reqs_progress = []
            selected_count = group_selections.get(group.id, 0)
            completed_count = 0
            
            for req in reqs:
                # If pool group, requirement is only visible/active if it has been selected
                is_selected = req.id in selected_req_ids
                
                # Determine status
                req_progress = progress_map.get(req.id)
                status = "not_started"
                started_at = None
                completed_at = None
                notes = None
                
                if req_progress:
                    status = req_progress.status
                    started_at = req_progress.started_at
                    completed_at = req_progress.completed_at
                    notes = req_progress.notes

                # Resolve start date for prediction
                resolved_start = started_at or award_start_date or user.joined_section_at
                earliest_finish_date = None
                if req.min_service_months is not None and resolved_start is not None:
                    earliest_finish_date = add_months(resolved_start, req.min_service_months)

                # Check eligibility dynamically
                is_eligible = True
                reason = None
                
                if req.min_age is not None and age < float(req.min_age):
                    is_eligible = False
                    reason = f"Minimum age required: {req.min_age} years (Current: {age:.1f})"
                elif req.max_age is not None and age > float(req.max_age):
                    is_eligible = False
                    reason = f"Maximum age limit exceeded: {req.max_age} years (Current: {age:.1f})"
                elif earliest_finish_date is not None:
                    check_date = completed_at or date.today()
                    if check_date < earliest_finish_date:
                        is_eligible = False
                        reason = f"Service constraint not met. Earliest completion: {earliest_finish_date}"
                    
                if status == "completed":
                    completed_count += 1
                    
                reqs_progress.append(
                    RequirementProgressDetail(
                        id=req.id,
                        name=req.name,
                        description=req.description,
                        is_mandatory=req.is_mandatory,
                        evidence_required=req.evidence_required,
                        min_age=req.min_age,
                        max_age=req.max_age,
                        min_service_months=req.min_service_months,
                        status=status,
                        started_at=started_at,
                        completed_at=completed_at,
                        earliest_finish_date=earliest_finish_date,
                        notes=notes,
                        is_eligible=is_eligible,
                        reason_ineligible=reason
                    )
                )
                
            # Compute counts towards award completion
            if group.is_pool:
                total_reqs += group.min_select
                completed_reqs += min(completed_count, group.min_select)
            else:
                total_reqs += len(reqs)
                completed_reqs += completed_count
                
            award_groups_progress.append(
                RequirementGroupProgress(
                    id=group.id,
                    name=group.name,
                    description=group.description,
                    is_pool=group.is_pool,
                    min_select=group.min_select,
                    max_select=group.max_select,
                    requirements=reqs_progress,
                    selected_count=selected_count,
                    completed_count=completed_count
                )
            )
            
        percent = (completed_reqs / total_reqs * 100.0) if total_reqs > 0 else 0.0
        is_completed = (completed_reqs >= total_reqs) and (total_reqs > 0)
        
        awards_progress.append(
            AwardProgressDetail(
                id=award.id,
                name=award.name,
                description=award.description,
                badge_image_url=award.badge_image_url,
                min_age=award.min_age,
                max_age=award.max_age,
                min_service_months=award.min_service_months,
                prerequisite_award_id=award.prerequisite_award_id,
                is_optional=award.is_optional,
                min_months_after_prereq_started=award.min_months_after_prereq_started,
                start_date_follows_prereq=award.start_date_follows_prereq,
                started_at=scout_award.started_at if scout_award else None,
                completed_at=scout_award.completed_at if scout_award else None,
                groups=award_groups_progress,
                percent_completed=round(percent, 1),
                is_completed=is_completed
            )
        )
        
    return SectionProgressSummary(
        id=section.id,
        name=section.name,
        color_hex=section.color_hex,
        icon_name=section.icon_name,
        awards=awards_progress
    )


# ─── EVALUATE AWARD COMPLETIONS ───────────────────────────────

async def evaluate_award_completions(
    db: AsyncSession,
    user_id: str,
    req_id: str,
    completed_at_date: date
) -> None:
    """Evaluates if the scout has completed the award containing the requirement."""
    # Find the award linked to this requirement
    award_res = await db.execute(
        select(Award)
        .join(RequirementGroup, RequirementGroup.award_id == Award.id)
        .join(Requirement, Requirement.group_id == RequirementGroup.id)
        .where(Requirement.id == req_id)
    )
    award = award_res.scalar_one_or_none()
    if not award:
        return
        
    # Check if already completed
    complete_res = await db.execute(
        select(ScoutAward).where(
            ScoutAward.user_id == user_id,
            ScoutAward.award_id == award.id
        )
    )
    scout_award = complete_res.scalar_one_or_none()
    if scout_award and scout_award.completed_at:
        return
        
    # Retrieve groups for this award
    groups_res = await db.execute(
        select(RequirementGroup).where(RequirementGroup.award_id == award.id, RequirementGroup.is_active == True)
    )
    groups = groups_res.scalars().all()
    
    # Check completions for each group
    for group in groups:
        # Requirements in group
        reqs_res = await db.execute(
            select(Requirement).where(Requirement.group_id == group.id, Requirement.is_active == True)
        )
        reqs = reqs_res.scalars().all()
        req_ids = {r.id for r in reqs}
        
        # Completed requirements in group
        prog_res = await db.execute(
            select(ScoutProgress).where(
                ScoutProgress.user_id == user_id,
                ScoutProgress.requirement_id.in_(list(req_ids)),
                ScoutProgress.status == "completed"
            )
        )
        completed_count = len(prog_res.scalars().all())
        
        if group.is_pool:
            if completed_count < group.min_select:
                return # Not completed this group
        else:
            if completed_count < len(reqs):
                return # Not completed all mandatory items
                
    # If we reached here, the award is completed!
    if scout_award:
        scout_award.completed_at = completed_at_date
    else:
        scout_award = ScoutAward(
            id=str(uuid4()),
            user_id=user_id,
            award_id=award.id,
            started_at=completed_at_date,
            completed_at=completed_at_date
        )
        db.add(scout_award)
    await db.flush()


# ─── AWARD-LEVEL DATE MANAGEMENT ──────────────────────────────────

async def _get_prerequisite_chain(db: AsyncSession, award_id: str) -> list:
    """
    Returns all uncompleted ancestor awards (prerequisites, grandprerequisites, etc.)
    in order from the oldest ancestor to the direct parent.
    """
    chain = []
    visited = set()
    current_id = award_id
    while current_id:
        if current_id in visited:
            break  # Guard against circular references
        visited.add(current_id)
        award_res = await db.execute(select(Award).where(Award.id == current_id))
        award = award_res.scalar_one_or_none()
        if not award or not award.prerequisite_award_id:
            break
        chain.append(award.prerequisite_award_id)
        current_id = award.prerequisite_award_id
    # chain is [direct_parent, grandparent, ...] – reverse for oldest-first order
    return list(reversed(chain))


async def complete_award_with_propagation(
    db: AsyncSession,
    user_id: str,
    award_id: str,
    completed_at: Optional[date] = None,
    propagate_to_parents: bool = True,
) -> list[str]:
    """
    Marks an award (and optionally its entire prerequisite tree) as completed.
    Returns list of award IDs that were completed by this call.

    Parent propagation strategy:
    - Walk up the prerequisite chain, collecting all ancestors.
    - Each uncompleted ancestor is completed at `completed_at - N days` where N is
      its distance from the target award (oldest ancestor gets the earliest date).
    - The target award itself is completed at `completed_at`.
    """
    target_date = completed_at or date.today()
    completed_ids = []

    if propagate_to_parents:
        ancestor_ids = await _get_prerequisite_chain(db, award_id)
        # Complete ancestors oldest-first; each gets target_date minus its distance
        from datetime import timedelta
        for offset, ancestor_id in enumerate(ancestor_ids):
            distance = len(ancestor_ids) - offset  # oldest ancestor = largest offset
            ancestor_date = target_date - timedelta(days=distance)

            sa_res = await db.execute(
                select(ScoutAward).where(
                    ScoutAward.user_id == user_id,
                    ScoutAward.award_id == ancestor_id
                )
            )
            sa = sa_res.scalar_one_or_none()
            if sa:
                if not sa.completed_at:
                    sa.completed_at = ancestor_date
                    if not sa.started_at or sa.started_at > ancestor_date:
                        sa.started_at = ancestor_date
                    completed_ids.append(ancestor_id)
            else:
                db.add(ScoutAward(
                    id=str(uuid4()),
                    user_id=user_id,
                    award_id=ancestor_id,
                    started_at=ancestor_date,
                    completed_at=ancestor_date,
                ))
                completed_ids.append(ancestor_id)

    # Complete the target award itself
    sa_res = await db.execute(
        select(ScoutAward).where(
            ScoutAward.user_id == user_id,
            ScoutAward.award_id == award_id
        )
    )
    sa = sa_res.scalar_one_or_none()
    if sa:
        sa.completed_at = target_date
        if not sa.started_at or sa.started_at > target_date:
            sa.started_at = target_date
    else:
        db.add(ScoutAward(
            id=str(uuid4()),
            user_id=user_id,
            award_id=award_id,
            started_at=target_date,
            completed_at=target_date,
        ))
    completed_ids.append(award_id)
    await db.flush()
    return completed_ids


async def update_award_dates(
    db: AsyncSession,
    user_id: str,
    award_id: str,
    started_at: Optional[date] = None,
    completed_at: Optional[date] = None,
) -> ScoutAward:
    """
    Lets a member set custom start and/or completion dates for their ScoutAward record.
    Creates the record if it doesn't exist yet.
    """
    sa_res = await db.execute(
        select(ScoutAward).where(
            ScoutAward.user_id == user_id,
            ScoutAward.award_id == award_id
        )
    )
    sa = sa_res.scalar_one_or_none()

    if sa:
        if started_at is not None:
            sa.started_at = started_at
        if completed_at is not None:
            sa.completed_at = completed_at
    else:
        # Need at least a started_at to create the record
        start = started_at or completed_at or date.today()
        sa = ScoutAward(
            id=str(uuid4()),
            user_id=user_id,
            award_id=award_id,
            started_at=start,
            completed_at=completed_at,
        )
        db.add(sa)

    await db.flush()
    return sa
