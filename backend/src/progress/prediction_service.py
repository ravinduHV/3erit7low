import calendar
from datetime import date, datetime
from typing import List, Optional, Dict
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from src.db.models import User, Section, Award, ScoutAward
from src.progress.service import add_months, calculate_age
from src.progress.schemas import PredictionResponse, RecommendationItem

def get_age_date(birth_date: date, target_age: float) -> date:
    """Calculates the exact date a user reaches a target decimal age."""
    years = int(target_age)
    months = int(round((target_age - years) * 12))
    
    # Handle year leap day edge case (Feb 29)
    try:
        target_date = birth_date.replace(year=birth_date.year + years)
    except ValueError:
        # Fallback if leap day doesn't exist in target year
        target_date = date(birth_date.year + years, 2, 28)
        
    if months > 0:
        target_date = add_months(target_date, months)
    return target_date

async def get_progress_predictions(db: AsyncSession, user: User) -> Optional[PredictionResponse]:
    """
    Predicts the highest achievable award and returns structured next-step
    recommendations based on age gates, service months, and prerequisites.
    """
    if not user.section_id or not user.date_of_birth:
        return None

    # 1. Fetch section and limits
    section_res = await db.execute(select(Section).where(Section.id == user.section_id))
    section = section_res.scalar_one_or_none()
    if not section:
        return None

    current_age = calculate_age(user.date_of_birth)
    
    # Calculate age-out date
    age_out_limit = section.max_age or 26.0  # default to Rover age out if none
    age_out_date = get_age_date(user.date_of_birth, age_out_limit)
    
    today = date.today()
    remaining_days = max(0, (age_out_date - today).days)
    is_aging_out_warning = remaining_days < 180  # Less than 6 months left warning

    # 2. Fetch all section awards
    awards_res = await db.execute(
        select(Award)
        .where(Award.section_id == section.id, Award.is_active == True)
        .order_by(Award.display_order)
    )
    awards = list(awards_res.scalars().all())

    # 3. Fetch completed awards
    completed_res = await db.execute(
        select(ScoutAward).where(ScoutAward.user_id == user.id)
    )
    completed_awards = {ca.award_id: ca for ca in completed_res.scalars().all()}

    # 4. Map award IDs to objects for easy lookups
    awards_map = {a.id: a for a in awards}

    # 5. Iteratively calculate earliest possible completion date for each award
    earliest_completion_dates: Dict[str, date] = {}
    recommendations: List[RecommendationItem] = []
    
    highest_achievable_id: Optional[str] = None
    highest_achievable_name: Optional[str] = None

    for award in awards:
        is_completed = award.id in completed_awards
        completion_record = completed_awards.get(award.id)
        
        # Determine base starting date for this award's calculations
        prereq_date = None
        if award.prerequisite_award_id:
            prereq_date = earliest_completion_dates.get(award.prerequisite_award_id)
            
        # Fallback starting point if no prerequisite or prereq date is not calculable
        if not prereq_date:
            prereq_date = user.joined_section_at or today

        # Calculate service month target date
        min_service = award.min_service_months or 0
        service_target_date = add_months(prereq_date, min_service)

        # Calculate age gate target date
        age_gate_date = today
        if award.min_age:
            age_gate_date = get_age_date(user.date_of_birth, award.min_age)

        # Earliest completion date is the max of: [today, service target, age gate]
        earliest_possible_date = max(today, service_target_date, age_gate_date)
        
        # Override with actual completion date if completed
        if is_completed and completion_record and completion_record.completed_at:
            # Cast completion_record.completed_at to date (if it's datetime)
            comp_at = completion_record.completed_at
            if isinstance(comp_at, datetime):
                comp_at = comp_at.date()
            earliest_possible_date = comp_at

        # Save calculations
        earliest_completion_dates[award.id] = earliest_possible_date

        # Check age out bounds for award
        is_achievable = earliest_possible_date <= age_out_date
        if award.max_age:
            award_max_date = get_age_date(user.date_of_birth, award.max_age)
            if earliest_possible_date > award_max_date:
                is_achievable = False

        # Update highest achievable non-optional award
        if is_achievable and not award.is_optional and not is_completed:
            # It's achievable and mandatory!
            highest_achievable_id = award.id
            highest_achievable_name = award.name
        elif is_completed and not award.is_optional:
            # User already achieved it, so it is the current highest achieved
            highest_achievable_id = award.id
            highest_achievable_name = award.name

        # 6. Build recommendation logic for this award
        status = "completed"
        reason = "You have completed this award!"
        
        if not is_completed:
            if not is_achievable:
                status = "locked_age"
                reason = "Aged out. You cannot complete this award before reaching the section age limit."
            else:
                # Find why it is locked or recommended
                prereq_ok = True
                prereq_name = ""
                if award.prerequisite_award_id:
                    prereq_ok = award.prerequisite_award_id in completed_awards
                    prereq_name = awards_map.get(award.prerequisite_award_id).name if awards_map.get(award.prerequisite_award_id) else "Prerequisite"

                age_ok = True
                if award.min_age and current_age < award.min_age:
                    age_ok = False

                service_ok = True
                if min_service > 0:
                    # Check service months relative to prereq completion date or joined date
                    joined_base = user.joined_section_at or today
                    comp_base = completed_awards.get(award.prerequisite_award_id).completed_at if (award.prerequisite_award_id and award.prerequisite_award_id in completed_awards) else joined_base
                    if isinstance(comp_base, datetime):
                        comp_base = comp_base.date()
                    
                    # Calculate service months from the completion of prerequisite
                    days_diff = (today - comp_base).days
                    current_service_months = int(days_diff / 30.44)
                    if current_service_months < min_service:
                        service_ok = False

                if not prereq_ok:
                    status = "locked_prerequisite"
                    reason = f"Prerequisite award '{prereq_name}' is not yet completed."
                elif not age_ok:
                    status = "locked_age"
                    reason = f"Minimum age gate of {award.min_age} years not reached. Eligible on {age_gate_date}."
                elif not service_ok:
                    status = "locked_service"
                    reason = f"Minimum service period constraint of {min_service} months from previous badge not met. Eligible on {service_target_date}."
                else:
                    status = "recommended"
                    reason = "You are currently eligible! Focus on completing this award's requirement groups."

        recommendations.append(
            RecommendationItem(
                award_id=award.id,
                award_name=award.name,
                status=status,
                reason=reason,
                target_completion_date=earliest_possible_date
            )
        )

    # If all awards are completed, the highest achievable is the last award
    if all(award.id in completed_awards for award in awards if not award.is_optional) and awards:
        last_mandatory = [a for a in awards if not a.is_optional]
        if last_mandatory:
            highest_achievable_id = last_mandatory[-1].id
            highest_achievable_name = last_mandatory[-1].name

    return PredictionResponse(
        current_age=round(current_age, 2),
        remaining_days_in_section=remaining_days,
        highest_achievable_award_id=highest_achievable_id,
        highest_achievable_award_name=highest_achievable_name,
        is_aging_out_warning=is_aging_out_warning,
        recommendations=recommendations
    )
