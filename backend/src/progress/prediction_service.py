import calendar
from datetime import date, datetime, timedelta
from typing import List, Optional, Dict, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from src.db.models import User, Section, Award, ScoutAward
from src.progress.service import add_months, calculate_age
from src.progress.schemas import PredictionResponse, RecommendationItem


def get_age_date(birth_date: date, target_age: float) -> date:
    """Calculates the exact date a user reaches a target decimal age."""
    years = int(target_age)
    months = int(round((target_age - years) * 12))

    try:
        target_date = birth_date.replace(year=birth_date.year + years)
    except ValueError:
        target_date = date(birth_date.year + years, 2, 28)

    if months > 0:
        target_date = add_months(target_date, months)
    return target_date


async def get_progress_predictions(db: AsyncSession, user: User) -> Optional[PredictionResponse]:
    """
    Predicts the highest achievable award and returns structured next-step
    recommendations based on:
      - Age gates (min/max age)
      - Service period constraints (min_service_months from award START date)
      - Engagement constraints (min_months_after_prereq_started: N months after prereq STARTED)
      - Cross-section credit (linked_section_id carries forward service base date)
      - Member-configured dates (ScoutAward.started_at / completed_at overrides)
      - start_date_follows_prereq toggle
    """
    if not user.section_id or not user.date_of_birth:
        return None

    # 1. Fetch section + linked predecessor section for cross-section credit
    section_res = await db.execute(select(Section).where(Section.id == user.section_id))
    section = section_res.scalar_one_or_none()
    if not section:
        return None

    current_age = calculate_age(user.date_of_birth)
    today = date.today()

    # Age-out date
    age_out_limit = float(section.max_age) if section.max_age else 26.0
    age_out_date = get_age_date(user.date_of_birth, age_out_limit)

    remaining_days = max(0, (age_out_date - today).days)
    is_aging_out_warning = remaining_days < 180

    # Cross-section credit: if section has a linked predecessor, use the member's
    # join date in that section as an earlier service base.
    service_base_date = user.joined_section_at or today
    if section.linked_section_id:
        # Fetch the user's join date from the linked section (stored as joined_section_at
        # on a historical profile record). For now we check if the user has a ScoutAward
        # completed in ANY award that belongs to the linked section — the earliest such
        # started_at date acts as the effective service base.
        linked_awards_res = await db.execute(
            select(Award).where(
                Award.section_id == section.linked_section_id,
                Award.is_active == True
            )
        )
        linked_award_ids = {a.id for a in linked_awards_res.scalars().all()}
        if linked_award_ids:
            linked_scout_awards_res = await db.execute(
                select(ScoutAward).where(
                    ScoutAward.user_id == user.id,
                    ScoutAward.award_id.in_(list(linked_award_ids))
                )
            )
            linked_records = linked_scout_awards_res.scalars().all()
            if linked_records:
                earliest_linked = min(
                    (r.started_at for r in linked_records if r.started_at),
                    default=None
                )
                if earliest_linked and earliest_linked < service_base_date:
                    service_base_date = earliest_linked

    # 2. Fetch all section awards
    awards_res = await db.execute(
        select(Award)
        .where(Award.section_id == section.id, Award.is_active == True)
        .order_by(Award.display_order)
    )
    awards = list(awards_res.scalars().all())

    # 3. Fetch all ScoutAward records for user (completed + in-progress)
    sa_res = await db.execute(select(ScoutAward).where(ScoutAward.user_id == user.id))
    scout_awards: Dict[str, ScoutAward] = {sa.award_id: sa for sa in sa_res.scalars().all()}

    completed_awards = {
        award_id: sa for award_id, sa in scout_awards.items() if sa.completed_at
    }

    # 4. Map award IDs to objects
    awards_map: Dict[str, Award] = {a.id: a for a in awards}

    # 5. Iteratively calculate earliest possible START and COMPLETION date per award
    #    earliest_start_dates[award_id]  = earliest date the member can BEGIN this award
    #    earliest_finish_dates[award_id] = earliest date the member can COMPLETE this award
    earliest_start_dates: Dict[str, date] = {}
    earliest_finish_dates: Dict[str, date] = {}

    recommendations: List[RecommendationItem] = []
    highest_achievable_id: Optional[str] = None
    highest_achievable_name: Optional[str] = None

    for award in awards:
        is_completed = award.id in completed_awards
        sa_record = scout_awards.get(award.id)

        # ── Determine prerequisite anchor dates ──────────────────────────────
        prereq_id = award.prerequisite_award_id
        prereq_sa = scout_awards.get(prereq_id) if prereq_id else None

        # Actual prereq completion date (if completed)
        prereq_completed_at: Optional[date] = None
        if prereq_sa and prereq_sa.completed_at:
            d = prereq_sa.completed_at
            prereq_completed_at = d.date() if isinstance(d, datetime) else d

        # Actual prereq start date (for engagement constraint)
        prereq_started_at: Optional[date] = None
        if prereq_sa and prereq_sa.started_at:
            d = prereq_sa.started_at
            prereq_started_at = d.date() if isinstance(d, datetime) else d
        elif prereq_id and prereq_id in earliest_start_dates:
            prereq_started_at = earliest_start_dates[prereq_id]

        # Forecasted prereq dates (if prereq not yet completed/started)
        if not prereq_completed_at and prereq_id in earliest_finish_dates:
            prereq_completed_at = earliest_finish_dates[prereq_id]
        if not prereq_started_at and prereq_id in earliest_start_dates:
            prereq_started_at = earliest_start_dates[prereq_id]

        # Fallback: section join date (with cross-section credit applied)
        base = prereq_completed_at or service_base_date

        # ── Determine member's custom/actual START date for this award ────────
        member_started_at: Optional[date] = None
        if sa_record and sa_record.started_at:
            d = sa_record.started_at
            member_started_at = d.date() if isinstance(d, datetime) else d

        # ── Calculate earliest START date ─────────────────────────────────────
        # Constraint 1: start_date_follows_prereq → must start no earlier than prereq completed
        earliest_start = today
        if award.start_date_follows_prereq and prereq_completed_at:
            earliest_start = max(earliest_start, prereq_completed_at)

        # Constraint 2: engagement constraint → start after N months from prereq START
        if award.min_months_after_prereq_started and prereq_started_at:
            engagement_unlock = add_months(prereq_started_at, award.min_months_after_prereq_started)
            earliest_start = max(earliest_start, engagement_unlock)

        # Constraint 3: min_age gate
        age_gate_date = today
        if award.min_age:
            age_gate_date = get_age_date(user.date_of_birth, float(award.min_age))
            earliest_start = max(earliest_start, age_gate_date)

        # If member has already set a custom start, use the later of member's date vs calculated
        if member_started_at:
            effective_start = max(member_started_at, earliest_start)
        else:
            effective_start = earliest_start

        earliest_start_dates[award.id] = effective_start

        # ── Calculate earliest COMPLETION date ────────────────────────────────
        min_service = award.min_service_months or 0
        service_target_date = add_months(effective_start, min_service)
        earliest_finish = max(today, service_target_date)

        # Override with actual completion date if already done
        if is_completed and sa_record and sa_record.completed_at:
            comp_at = sa_record.completed_at
            if isinstance(comp_at, datetime):
                comp_at = comp_at.date()
            earliest_finish = comp_at

        earliest_finish_dates[award.id] = earliest_finish

        # ── Achievability check ───────────────────────────────────────────────
        is_achievable = earliest_finish <= age_out_date
        if award.max_age:
            award_max_date = get_age_date(user.date_of_birth, float(award.max_age))
            if earliest_finish > award_max_date:
                is_achievable = False

        # Track highest mandatory award
        if not award.is_optional:
            if is_completed:
                highest_achievable_id = award.id
                highest_achievable_name = award.name
            elif is_achievable:
                highest_achievable_id = award.id
                highest_achievable_name = award.name

        # ── Build recommendation status ───────────────────────────────────────
        status = "completed"
        reason = "You have completed this award! 🎉"

        if not is_completed:
            if not is_achievable:
                status = "locked_age"
                reason = "Cannot complete before aging out of this section."
            else:
                prereq_ok = True
                engagement_ok = True
                age_ok = True
                service_ok = True
                engagement_unlock_date = None

                # Check prerequisite
                if prereq_id:
                    prereq_ok = prereq_id in completed_awards

                # Check engagement constraint (months after prereq STARTED)
                if award.min_months_after_prereq_started:
                    if prereq_started_at:
                        engagement_unlock_date = add_months(prereq_started_at, award.min_months_after_prereq_started)
                        if today < engagement_unlock_date:
                            engagement_ok = False
                    elif prereq_id and prereq_id not in completed_awards:
                        engagement_ok = False  # prereq not even started

                # Check age gate
                if award.min_age and current_age < float(award.min_age):
                    age_ok = False

                # Check service period (from effective start)
                if min_service > 0 and member_started_at:
                    days_since_start = (today - member_started_at).days
                    current_service = int(days_since_start / 30.44)
                    if current_service < min_service:
                        service_ok = False
                elif min_service > 0 and not member_started_at:
                    service_ok = False  # Not even started yet

                if not prereq_ok:
                    prereq_award = awards_map.get(prereq_id) if prereq_id else None
                    prereq_name = prereq_award.name if prereq_award else "Prerequisite"
                    status = "locked_prerequisite"
                    reason = f"Complete '{prereq_name}' first."
                elif not engagement_ok:
                    if engagement_unlock_date:
                        reason = (
                            f"Can start {award.min_months_after_prereq_started} months "
                            f"after beginning the prerequisite. Unlocks on {engagement_unlock_date}."
                        )
                    else:
                        reason = (
                            f"Start the prerequisite first, then wait "
                            f"{award.min_months_after_prereq_started} months."
                        )
                    status = "locked_service"
                elif not age_ok:
                    status = "locked_age"
                    reason = f"Minimum age {award.min_age} not reached. Eligible on {age_gate_date}."
                elif not service_ok:
                    status = "locked_service"
                    reason = (
                        f"Service period of {min_service} months from your award start date "
                        f"not met. Eligible on {service_target_date}."
                    )
                else:
                    status = "recommended"
                    reason = "You are eligible! Focus on completing all requirement groups."

        recommendations.append(
            RecommendationItem(
                award_id=award.id,
                award_name=award.name,
                status=status,
                reason=reason,
                target_completion_date=earliest_finish if not is_completed else None
            )
        )

    return PredictionResponse(
        current_age=round(current_age, 2),
        remaining_days_in_section=remaining_days,
        highest_achievable_award_id=highest_achievable_id,
        highest_achievable_award_name=highest_achievable_name,
        is_aging_out_warning=is_aging_out_warning,
        recommendations=recommendations
    )
