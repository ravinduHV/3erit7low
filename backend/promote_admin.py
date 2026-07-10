import asyncio
import sys
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine
from src.core.config import settings

async def promote_user(email: str):
    engine = create_async_engine(settings.DATABASE_URL)
    async with engine.begin() as conn:
        # 1. Verify user exists in the local database
        res = await conn.execute(
            text("SELECT id, role FROM scout.users WHERE email = :email"),
            {"email": email}
        )
        row = res.fetchone()
        if not row:
            print(f"Error: User with email '{email}' does not exist in the local database.")
            print("Please sign up or log in first from the frontend to sync the user profile.")
            return

        # 2. Promote to admin
        await conn.execute(
            text("UPDATE scout.users SET role = 'admin' WHERE email = :email"),
            {"email": email}
        )
        print(f"Success: User '{email}' promoted from '{row[1]}' to 'admin'!")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python promote_admin.py <email>")
    else:
        email_arg = sys.argv[1].strip()
        asyncio.run(promote_user(email_arg))
