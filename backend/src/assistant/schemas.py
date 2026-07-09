from pydantic import BaseModel
from typing import Optional, List

class SuggestionResponse(BaseModel):
    type: str          # next_step | reminder | milestone | tip
    priority: int      # 1 (high) to 5 (low)
    title: str
    message: str
    action: Optional[str] = None       # open_requirement | open_award
    target_id: Optional[str] = None    # UUID associated with action

class AssistantResponse(BaseModel):
    suggestions: List[SuggestionResponse]
