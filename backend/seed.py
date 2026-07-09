import asyncio
from datetime import date, datetime
from uuid import uuid4
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from src.core.config import settings
from src.db.models import Section, Award, RequirementGroup, Requirement, User, ScoutProgress, RequirementPoolSelection, ScoutAward

async def seed_data():
    print("Connecting to database for seeding...")
    engine = create_async_engine(settings.DATABASE_URL, echo=True)
    async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        async with session.begin():
            # 1. Clear existing syllabus tables in scout schema (to avoid duplicates on re-run)
            print("Cleaning up old syllabus records...")
            await session.execute(ScoutAward.__table__.delete())
            await session.execute(ScoutProgress.__table__.delete())
            await session.execute(RequirementPoolSelection.__table__.delete())
            await session.execute(User.__table__.delete())
            await session.execute(Requirement.__table__.delete())
            await session.execute(RequirementGroup.__table__.delete())
            await session.execute(Award.__table__.delete())
            await session.execute(Section.__table__.delete())
            
            # 2. Seed Sections
            print("Seeding Sections...")
            sections_data = [
                Section(
                    id="singithi",
                    name="Singithi Scout",
                    slug="singithi",
                    min_age=5.0,
                    max_age=7.0,
                    color_hex="#FCD34D",
                    icon_name="child_care",
                    description="Singithi Scouting (ages 5 to 7) focuses on early character building, teamwork, and active play.",
                    role_type="scout",
                    display_order=1
                ),
                Section(
                    id="cub",
                    name="Cub Scout",
                    slug="cub",
                    min_age=7.0,
                    max_age=10.5,
                    color_hex="#FB923C",
                    icon_name="pets",
                    description="Cub Scouting (ages 7 to 10.5) is filled with learning by doing, outdoor adventures, and earning progress stars.",
                    role_type="scout",
                    display_order=2
                ),
                Section(
                    id="junior",
                    name="Junior Scout",
                    slug="junior",
                    min_age=10.5,
                    max_age=14.5,
                    color_hex="#3B82F6",
                    icon_name="directions_run",
                    description="Junior Scouting (ages 10.5 to 14.5) fosters campcraft, survival skills, community service, and physical fitness.",
                    role_type="scout",
                    display_order=3
                ),
                Section(
                    id="senior",
                    name="Senior Scout",
                    slug="senior",
                    min_age=14.5,
                    max_age=18.0,
                    color_hex="#16A34A",
                    icon_name="terrain",
                    description="Senior Scouting (ages 14.5 to 18) offers deep adventure, leadership roles, and the Prime Minister / President's award pathways.",
                    role_type="scout",
                    display_order=4
                ),
                Section(
                    id="rover",
                    name="Rover Scout",
                    slug="rover",
                    min_age=18.0,
                    max_age=26.0,
                    color_hex="#7C3AED",
                    icon_name="explore",
                    description="Rover Scouting (ages 18 to 26) focuses on community integration, personal goals, and service projects.",
                    role_type="scout",
                    display_order=5
                ),
                Section(
                    id="leader",
                    name="Scout Leader",
                    slug="leader",
                    min_age=18.0,
                    max_age=None,
                    color_hex="#9F1239",
                    icon_name="supervisor_account",
                    description="Leader Training Track manages progress from fundamental modules, practical assessments, and up to the Wood Badge.",
                    role_type="leader",
                    display_order=6
                ),
            ]
            session.add_all(sections_data)
            
            # 3. Seed Junior Scout Awards & Requirements (as a comprehensive sample)
            print("Seeding Junior Scout Awards & Requirements...")
            # Award 1: Membership Badge
            membership_award = Award(
                id="jr_membership",
                section_id="junior",
                name="Membership Badge",
                description="The entry badge for all Junior Scouts. Must learn basic laws, promise, and salute.",
                badge_image_url="assets/badges/jr_membership.png",
                min_age=10.5,
                display_order=1
            )
            session.add(membership_award)
            
            # Group 1: Core Knowledge (Mandatory)
            group_core = RequirementGroup(
                id="jr_mem_core",
                award_id="jr_membership",
                name="Core Knowledge",
                description="Fundamental scouting principles",
                is_pool=False,
                display_order=1
            )
            session.add(group_core)
            
            # Requirements for Core Knowledge
            req1 = Requirement(
                id="jr_mem_req_promise",
                group_id="jr_mem_core",
                name="Scout Promise & Law",
                description="Recite, understand, and explain the Scout Promise and the 10 Scout Laws of Sri Lanka.",
                is_mandatory=True,
                display_order=1
            )
            req2 = Requirement(
                id="jr_mem_req_history",
                group_id="jr_mem_core",
                name="Scouting History",
                description="Know the history of Lord Baden-Powell and how scouting started in Sri Lanka.",
                is_mandatory=True,
                display_order=2
            )
            session.add_all([req1, req2])
            
            # Group 2: Elective Hobbies (Selectable Pool: Choose 1)
            group_electives = RequirementGroup(
                id="jr_mem_electives",
                award_id="jr_membership",
                name="Elective Hobby",
                description="Choose one hobby to present to the troop",
                is_pool=True,
                min_select=1,
                max_select=1,
                display_order=2
            )
            session.add(group_electives)
            
            req_hobby1 = Requirement(
                id="jr_mem_req_hobby_stamp",
                group_id="jr_mem_electives",
                name="Stamp Collecting",
                description="Show a collection of at least 30 stamps and explain their historical details.",
                is_mandatory=False,
                display_order=1
            )
            req_hobby2 = Requirement(
                id="jr_mem_req_hobby_knot",
                group_id="jr_mem_electives",
                name="Knot Tying Mastery",
                description="Demonstrate and explain the uses of reef knot, sheet bend, and clove hitch.",
                is_mandatory=False,
                display_order=2
            )
            session.add_all([req_hobby1, req_hobby2])
            
            # Award 2: Scout Master's Award
            master_award = Award(
                id="jr_master",
                section_id="junior",
                name="Scout Master's Award",
                description="The second milestone, proving advanced knotting, first aid, and camping.",
                badge_image_url="assets/badges/jr_master.png",
                min_age=11.0,
                min_service_months=3,
                display_order=2
            )
            session.add(master_award)
            
            group_master_core = RequirementGroup(
                id="jr_master_core",
                award_id="jr_master",
                name="Camping & First Aid",
                description="Practical scouting operations",
                is_pool=False,
                display_order=1
            )
            session.add(group_master_core)
            
            req_fa = Requirement(
                id="jr_master_req_fa",
                group_id="jr_master_core",
                name="Basic First Aid",
                description="Demonstrate how to treat simple cuts, burns, sprains, and bleedings.",
                is_mandatory=True,
                display_order=1
            )
            req_camp = Requirement(
                id="jr_master_req_camp",
                group_id="jr_master_core",
                name="Pitch a Tent",
                description="Understand tent parts and actively pitch a standard patrol tent with teammates.",
                is_mandatory=True,
                display_order=2
            )
            session.add_all([req_fa, req_camp])
            
            # 4. Seed Scout Leader Awards & Requirements (Wood Badge Track)
            print("Seeding Scout Leader Wood Badge Track...")
            leader_phase1 = Award(
                id="ld_phase1",
                section_id="leader",
                name="Module Training Phase 1",
                description="Introduction to scout group leadership, child safety, and program planning.",
                badge_image_url="assets/badges/ld_phase1.png",
                min_age=18.0,
                display_order=1
            )
            session.add(leader_phase1)
            
            ld_p1_group = RequirementGroup(
                id="ld_p1_core",
                award_id="ld_phase1",
                name="Core Modules",
                description="Fundamental leader requirements",
                is_pool=False,
                display_order=1
            )
            session.add(ld_p1_group)
            
            ld_p1_req1 = Requirement(
                id="ld_p1_req_child_safety",
                group_id="ld_p1_core",
                name="Safe from Harm Module",
                description="Complete the Child Safety certificate course and verify compliance guidelines.",
                is_mandatory=True,
                display_order=1
            )
            ld_p1_req2 = Requirement(
                id="ld_p1_req_fundamentals",
                group_id="ld_p1_core",
                name="Fundamentals of Scouting",
                description="Attend the District Training Course and present a summary of scout methods.",
                is_mandatory=True,
                display_order=2
            )
            session.add_all([ld_p1_req1, ld_p1_req2])
            
            # Award: Wood Badge
            wood_badge = Award(
                id="ld_wood_badge",
                section_id="leader",
                name="Wood Badge Award",
                description="The ultimate leadership award. Requires practical ticket completion and leadership assessment.",
                badge_image_url="assets/badges/ld_wood_badge.png",
                min_age=20.0,
                min_service_months=12,
                display_order=3
            )
            session.add(wood_badge)
            
            wb_group = RequirementGroup(
                id="ld_wb_core",
                award_id="ld_wood_badge",
                name="Wood Badge Requirements",
                description="Practical leadership and project management",
                is_pool=False,
                display_order=1
            )
            session.add(wb_group)
            
            wb_req1 = Requirement(
                id="ld_wb_req_ticket",
                group_id="ld_wb_core",
                name="Complete the 5 Tickets",
                description="Design and complete 5 practical service tickets in your local troop over 12 months.",
                is_mandatory=True,
                display_order=1
            )
            wb_req2 = Requirement(
                id="ld_wb_req_assessment",
                group_id="ld_wb_core",
                name="Practical Assessment Camp",
                description="Demonstrate camp leadership skills during the 3-day regional Wood Badge training camp.",
                is_mandatory=True,
                display_order=2
            )
            session.add_all([wb_req1, wb_req2])
            
            # 5. Create default Admin user for testing
            print("Creating default Admin user...")
            admin_user = User(
                id="default_admin_id",
                email="scout.admin@scout.lk",
                is_anonymous=False,
                display_name="Syllabus Admin",
                full_name="Syllabus Admin",
                role="admin",
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add(admin_user)
            
            # Also seed a mock leader and scout for testing
            mock_scout = User(
                id="mock_scout_id",
                email="scout.test@scout.lk",
                is_anonymous=False,
                display_name="Dilshan Perera",
                full_name="Dilshan Perera",
                role="scout",
                section_id="junior",
                date_of_birth=date(2013, 5, 10),  # ~13 years old
                joined_section_at=date(2025, 6, 1),
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add(mock_scout)
            
    print("Database seeding completed successfully!")
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(seed_data())
