import pytest
from datetime import date, datetime
from src.progress.service import calculate_age, calculate_service_months, check_eligibility, add_months
from src.db.models import Requirement

def test_calculate_age():
    # 1. Exact birthdate 10 years ago should return ~10.0
    dob = date(date.today().year - 10, date.today().month, date.today().day)
    age = calculate_age(dob)
    assert round(age) == 10

def test_calculate_service_months():
    # 2. Joined exactly 12 months ago should return 12
    joined_date = date(date.today().year - 1, date.today().month, date.today().day)
    months = calculate_service_months(joined_date)
    assert months == 12

def test_check_eligibility():
    # Test min_age constraint
    req = Requirement(
        id="test_req",
        group_id="test_group",
        name="Test",
        min_age=12.0,
        max_age=18.0,
        min_service_months=6
    )
    
    # 1. Scout too young: 10 years old, 12 months service
    eligible, reason = check_eligibility(req, age=10.0, service_months=12)
    assert not eligible
    assert "Minimum age required" in reason

    # 2. Scout too old: 20 years old, 12 months service
    eligible, reason = check_eligibility(req, age=20.0, service_months=12)
    assert not eligible
    assert "Maximum age limit exceeded" in reason

    # 3. Scout with insufficient service: 15 years old, 3 months service
    eligible, reason = check_eligibility(req, age=15.0, service_months=3)
    assert not eligible
    assert "Minimum service required" in reason

    # 4. Eligible scout: 15 years old, 12 months service
    eligible, reason = check_eligibility(req, age=15.0, service_months=12)
    assert eligible
    assert reason is None

def test_add_months():
    # Test adding 3 months to 2026-01-15 -> 2026-04-15
    d1 = date(2026, 1, 15)
    assert add_months(d1, 3) == date(2026, 4, 15)

    # Test adding 12 months to 2026-01-31 -> 2027-01-31
    d2 = date(2026, 1, 31)
    assert add_months(d2, 12) == date(2027, 1, 31)

    # Test leap year handling: Feb 29, 2024 + 12 months -> Feb 28, 2025
    d3 = date(2024, 2, 29)
    assert add_months(d3, 12) == date(2025, 2, 28)
