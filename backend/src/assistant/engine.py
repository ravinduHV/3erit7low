from datetime import datetime, date
from typing import List, Optional
from src.progress.schemas import SectionProgressSummary
from src.assistant.schemas import SuggestionResponse
from src.progress.service import calculate_age, calculate_service_months

def generate_suggestions(
    summary: SectionProgressSummary,
    dob: Optional[date],
    joined_at: Optional[date]
) -> List[SuggestionResponse]:
    """Evaluates rule-based suggestions based on the scout's progress summary."""
    suggestions: List[SuggestionResponse] = []
    
    # Calculate scout's stats
    age = calculate_age(dob)
    service_months = calculate_service_months(joined_at)
    
    # ─── SECTION-LEVEL RULES ───────────────────────────────────────
    # Rule 5: Warn section age cutoff if approaching max age
    # We will fetch a mock max_age or read from sections. Since we don't have Section directly,
    # we can deduce the max age cutoff if the section name has known rules, or we can add it later.
    # In Sri Lanka scouting, Singithi max is 7.0, Cub max is 10.5, Junior max is 14.5, Senior max is 18.0, Rover max is 26.0
    # Let's inspect summary name
    sec_name = summary.name.lower()
    max_age_cutoff = None
    if "singithi" in sec_name:
        max_age_cutoff = 7.0
    elif "cub" in sec_name:
        max_age_cutoff = 10.5
    elif "junior" in sec_name:
        max_age_cutoff = 14.5
    elif "senior" in sec_name:
        max_age_cutoff = 18.0
    elif "rover" in sec_name:
        max_age_cutoff = 26.0
        
    if max_age_cutoff and age > 0.0:
        time_left = max_age_cutoff - age
        if 0.0 < time_left <= 0.5:  # within 6 months
            suggestions.append(
                SuggestionResponse(
                    type="reminder",
                    priority=1,  # High priority
                    title="Age Cutoff Approaching!",
                    message=f"You are close to the maximum age of {max_age_cutoff} for {summary.name}. You have about {int(time_left * 12)} months left to complete your current progression!",
                )
            )

    # ─── AWARD-LEVEL RULES ─────────────────────────────────────────
    for award in summary.awards:
        # Rule 4: Celebrate completed award
        if award.is_completed:
            suggestions.append(
                SuggestionResponse(
                    type="milestone",
                    priority=2,
                    title=f"Congratulations on {award.name}!",
                    message=f"Spectacular! You have completed all requirements for the {award.name}. Talk to your Scout Master to receive your badge!",
                    action="open_award",
                    target_id=award.id
                )
            )
            continue  # No need for progression tips if completed
            
        # Check requirements within this award
        has_started_any = False
        in_progress_reqs = []
        mandatory_groups_completed = True
        pool_groups_needing_selection = []
        
        for group in award.groups:
            group_completed = True
            
            # Count completed
            comp_count = sum(1 for r in group.requirements if r.status == "completed")
            
            if group.is_pool:
                if comp_count < group.min_select:
                    group_completed = False
                # If they haven't selected enough pool items
                if group.selected_count < group.min_select:
                    pool_groups_needing_selection.append(group)
            else:
                for r in group.requirements:
                    if r.status != "completed":
                        group_completed = False
                        
            if not group_completed and not group.is_pool:
                # If it's a mandatory group and not complete, then mandatory groups aren't complete
                mandatory_groups_completed = False
                
            for req in group.requirements:
                if req.status in ["in_progress", "completed"]:
                    has_started_any = True
                if req.status == "in_progress":
                    in_progress_reqs.append(req)
                    
        # Rule 1: Suggest getting started
        if not has_started_any and award.min_age is not None and age >= float(award.min_age):
            suggestions.append(
                SuggestionResponse(
                    type="next_step",
                    priority=3,
                    title=f"Start {award.name}",
                    message=f"You are eligible to attempt the '{award.name}'. Let's check out the requirements and get started!",
                    action="open_award",
                    target_id=award.id
                )
            )
            
        # Rule 3: Prompt pool selections if mandatory tasks completed
        if mandatory_groups_completed and pool_groups_needing_selection:
            for pg in pool_groups_needing_selection:
                suggestions.append(
                    SuggestionResponse(
                        type="next_step",
                        priority=2,
                        title=f"Select Electives for {award.name}",
                        message=f"You completed the core requirements! Now select at least {pg.min_select} electives from the '{pg.name}' pool.",
                        action="open_award",
                        target_id=award.id
                    )
                )

        # Rule 2: Remind stalled requirement (in-progress requirements)
        for req in in_progress_reqs:
            # Let's say if we can check if it's been active for long. Since we don't pass full datetime fields
            # inside the summary detailed view, we can just suggest completing whatever is currently in_progress!
            suggestions.append(
                SuggestionResponse(
                    type="reminder",
                    priority=4,
                    title=f"Continue: {req.name}",
                    message=f"You are currently working on '{req.name}'. Don't forget to mark it completed once you finish!",
                    action="open_requirement",
                    target_id=req.id
                )
            )

    # If no specific suggestions generated, add a general tip
    if not suggestions:
        suggestions.append(
            SuggestionResponse(
                type="tip",
                priority=5,
                title="Explore Proficiency Badges",
                message="Did you know you can unlock special proficiency badges? Check out the awards list and ask your leader for ideas!",
            )
        )
        
    return suggestions
