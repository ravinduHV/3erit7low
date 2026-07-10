import pytest
from datetime import date, datetime, timedelta
from unittest.mock import AsyncMock, MagicMock
from src.progress.prediction_service import get_progress_predictions, get_age_date
from src.progress.service import complete_award_with_propagation
from src.db.models import User, Section, Award, ScoutAward

@pytest.mark.anyio
async def test_get_age_date():
    birth_date = date(2000, 5, 15)
    # reaches age 15
    assert get_age_date(birth_date, 15.0) == date(2015, 5, 15)
    # reaches age 15.5 (15 years, 6 months)
    assert get_age_date(birth_date, 15.5) == date(2015, 11, 15)

@pytest.mark.anyio
async def test_complete_award_with_propagation():
    db = AsyncMock()
    user_id = "test_user"
    award_id = "award_c"
    completed_at = date(2026, 7, 10)

    from unittest.mock import patch
    
    award_a = Award(id="award_a", prerequisite_award_id=None)
    award_b = Award(id="award_b", prerequisite_award_id="award_a")
    award_c = Award(id="award_c", prerequisite_award_id="award_b")

    mock_awards = {
        "award_c": award_c,
        "award_b": award_b,
        "award_a": award_a
    }

    def mock_execute_side_effect(query):
        q_str = str(query).lower()
        if "scout_award" in q_str:
            mock_result = MagicMock()
            mock_result.scalar_one_or_none.return_value = None
            mock_result.scalars.return_value.all.return_value = []
            return mock_result
        return MagicMock()

    db.execute.side_effect = mock_execute_side_effect
    db.add = MagicMock()

    with patch("src.progress.service._get_prerequisite_chain", AsyncMock(return_value=["award_a", "award_b"])):
        completed_ids = await complete_award_with_propagation(
            db,
            user_id=user_id,
            award_id=award_id,
            completed_at=completed_at,
            propagate_to_parents=True
        )

    # Should have completed award_a, award_b, award_c
    assert "award_a" in completed_ids
    assert "award_b" in completed_ids
    assert "award_c" in completed_ids
    
    # Check that db.add was called to create/update ScoutAward records
    assert db.add.call_count >= 1
