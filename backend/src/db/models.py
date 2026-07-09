from datetime import date, datetime
from typing import List, Optional
from sqlalchemy import String, Integer, Boolean, Numeric, Date, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from src.db.base import Base

class Section(Base):
    __tablename__ = "sections"

    id: Mapped[str] = mapped_column(String(50), primary_key=True)  # UUID stored as string
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    min_age: Mapped[Optional[float]] = mapped_column(Numeric(4, 1))
    max_age: Mapped[Optional[float]] = mapped_column(Numeric(4, 1))
    color_hex: Mapped[str] = mapped_column(String(7), nullable=False)
    icon_name: Mapped[Optional[str]] = mapped_column(String(100))
    description: Mapped[Optional[str]] = mapped_column(String(1000))
    display_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    role_type: Mapped[str] = mapped_column(String(20), default="scout", nullable=False) # scout | leader
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    awards: Mapped[List["Award"]] = relationship("Award", back_populates="section", cascade="all, delete-orphan", order_by="Award.display_order")
    users: Mapped[List["User"]] = relationship("User", back_populates="section")


class Award(Base):
    __tablename__ = "awards"

    id: Mapped[str] = mapped_column(String(50), primary_key=True)
    section_id: Mapped[str] = mapped_column(String(50), ForeignKey("sections.id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(1000))
    badge_image_url: Mapped[Optional[str]] = mapped_column(String(500))
    min_age: Mapped[Optional[float]] = mapped_column(Numeric(4, 1))
    max_age: Mapped[Optional[float]] = mapped_column(Numeric(4, 1))
    min_service_months: Mapped[Optional[int]] = mapped_column(Integer)
    display_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    section: Mapped["Section"] = relationship("Section", back_populates="awards")
    requirement_groups: Mapped[List["RequirementGroup"]] = relationship(
        "RequirementGroup", back_populates="award", cascade="all, delete-orphan", order_by="RequirementGroup.display_order"
    )
    completions: Mapped[List["ScoutAward"]] = relationship("ScoutAward", back_populates="award", cascade="all, delete-orphan")


class RequirementGroup(Base):
    __tablename__ = "requirement_groups"

    id: Mapped[str] = mapped_column(String(50), primary_key=True)
    award_id: Mapped[str] = mapped_column(String(50), ForeignKey("awards.id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(1000))
    is_pool: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    min_select: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    max_select: Mapped[Optional[int]] = mapped_column(Integer, default=1)
    display_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    award: Mapped["Award"] = relationship("Award", back_populates="requirement_groups")
    requirements: Mapped[List["Requirement"]] = relationship(
        "Requirement", back_populates="group", cascade="all, delete-orphan", order_by="Requirement.display_order"
    )
    pool_selections: Mapped[List["RequirementPoolSelection"]] = relationship("RequirementPoolSelection", back_populates="group", cascade="all, delete-orphan")


class Requirement(Base):
    __tablename__ = "requirements"

    id: Mapped[str] = mapped_column(String(50), primary_key=True)
    group_id: Mapped[str] = mapped_column(String(50), ForeignKey("requirement_groups.id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(300), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(2000))
    min_age: Mapped[Optional[float]] = mapped_column(Numeric(4, 1))
    max_age: Mapped[Optional[float]] = mapped_column(Numeric(4, 1))
    min_service_months: Mapped[Optional[int]] = mapped_column(Integer)
    is_mandatory: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    evidence_required: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    evidence_notes: Mapped[Optional[str]] = mapped_column(String(1000))
    reference_url: Mapped[Optional[str]] = mapped_column(String(500))
    display_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    group: Mapped["RequirementGroup"] = relationship("RequirementGroup", back_populates="requirements")
    progress_records: Mapped[List["ScoutProgress"]] = relationship("ScoutProgress", back_populates="requirement", cascade="all, delete-orphan")
    pool_selections: Mapped[List["RequirementPoolSelection"]] = relationship("RequirementPoolSelection", back_populates="requirement", cascade="all, delete-orphan")


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(50), primary_key=True)  # Synced from Neon Auth uuid
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    is_anonymous: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    display_name: Mapped[Optional[str]] = mapped_column(String(100))
    
    # Known-user fields
    full_name: Mapped[Optional[str]] = mapped_column(String(200))
    date_of_birth: Mapped[Optional[date]] = mapped_column(Date) # Required for onboarding, used for age-gate
    gender: Mapped[Optional[str]] = mapped_column(String(20))
    profile_image_url: Mapped[Optional[str]] = mapped_column(String(500))
    registration_number: Mapped[Optional[str]] = mapped_column(String(100))
    school_name: Mapped[Optional[str]] = mapped_column(String(200))
    troop_number: Mapped[Optional[str]] = mapped_column(String(50))
    district: Mapped[Optional[str]] = mapped_column(String(100))
    province: Mapped[Optional[str]] = mapped_column(String(100))

    # Common profile fields
    section_id: Mapped[Optional[str]] = mapped_column(String(50), ForeignKey("sections.id"), nullable=True)
    role: Mapped[str] = mapped_column(String(20), default="scout", nullable=False) # scout | leader | admin
    joined_section_at: Mapped[Optional[date]] = mapped_column(Date)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    section: Mapped[Optional["Section"]] = relationship("Section", back_populates="users")
    progress: Mapped[List["ScoutProgress"]] = relationship("ScoutProgress", foreign_keys="[ScoutProgress.user_id]", back_populates="user", cascade="all, delete-orphan")
    approved_progress: Mapped[List["ScoutProgress"]] = relationship("ScoutProgress", foreign_keys="[ScoutProgress.approved_by]", back_populates="approver")
    completions: Mapped[List["ScoutAward"]] = relationship("ScoutAward", back_populates="user", cascade="all, delete-orphan")
    pool_selections: Mapped[List["RequirementPoolSelection"]] = relationship("RequirementPoolSelection", back_populates="user", cascade="all, delete-orphan")


class RequirementPoolSelection(Base):
    __tablename__ = "requirement_pool_selections"
    __table_args__ = (
        UniqueConstraint("user_id", "requirement_group_id", "requirement_id", name="uq_user_group_requirement"),
        {"schema": "scout"}
    )

    id: Mapped[str] = mapped_column(String(50), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(50), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    requirement_group_id: Mapped[str] = mapped_column(String(50), ForeignKey("requirement_groups.id", ondelete="CASCADE"), nullable=False)
    requirement_id: Mapped[str] = mapped_column(String(50), ForeignKey("requirements.id", ondelete="CASCADE"), nullable=False)
    selected_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="pool_selections")
    group: Mapped["RequirementGroup"] = relationship("RequirementGroup", back_populates="pool_selections")
    requirement: Mapped["Requirement"] = relationship("Requirement", back_populates="pool_selections")


class ScoutProgress(Base):
    __tablename__ = "scout_progress"
    __table_args__ = (
        UniqueConstraint("user_id", "requirement_id", name="uq_user_requirement"),
        {"schema": "scout"}
    )

    id: Mapped[str] = mapped_column(String(50), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(50), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    requirement_id: Mapped[str] = mapped_column(String(50), ForeignKey("requirements.id", ondelete="CASCADE"), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="not_started", nullable=False) # not_started | in_progress | completed
    started_at: Mapped[Optional[date]] = mapped_column(Date)
    completed_at: Mapped[Optional[date]] = mapped_column(Date)
    notes: Mapped[Optional[str]] = mapped_column(String(1000))
    evidence_url: Mapped[Optional[str]] = mapped_column(String(500))
    approved_by: Mapped[Optional[str]] = mapped_column(String(50), ForeignKey("users.id"))
    approved_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    user: Mapped["User"] = relationship("User", foreign_keys=[user_id], back_populates="progress")
    approver: Mapped[Optional["User"]] = relationship("User", foreign_keys=[approved_by], back_populates="approved_progress")
    requirement: Mapped["Requirement"] = relationship("Requirement", back_populates="progress_records")


class ScoutAward(Base):
    __tablename__ = "scout_awards"
    __table_args__ = (
        UniqueConstraint("user_id", "award_id", name="uq_user_award"),
        {"schema": "scout"}
    )

    id: Mapped[str] = mapped_column(String(50), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(50), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    award_id: Mapped[str] = mapped_column(String(50), ForeignKey("awards.id", ondelete="CASCADE"), nullable=False)
    started_at: Mapped[date] = mapped_column(Date, nullable=False)
    completed_at: Mapped[Optional[date]] = mapped_column(Date)
    certificate_url: Mapped[Optional[str]] = mapped_column(String(500))
    notes: Mapped[Optional[str]] = mapped_column(String(1000))

    user: Mapped["User"] = relationship("User", back_populates="completions")
    award: Mapped["Award"] = relationship("Award", back_populates="completions")
