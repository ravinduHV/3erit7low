from datetime import datetime, date
from typing import Dict, Any, Optional
from jose import jwt, JWTError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from src.core.config import settings
from src.db.models import User

def decode_token(token: str) -> Dict[str, Any]:
    """Decodes the JWT token from Better Auth (Neon Auth) using the shared secret."""
    try:
        # Better Auth JWTs are signed with the BETTER_AUTH_SECRET using HS256
        payload = jwt.decode(
            token,
            settings.BETTER_AUTH_SECRET,
            algorithms=[settings.JWT_ALGORITHM],
            options={"verify_aud": False} # Better Auth does not always set audience
        )
        return payload
    except JWTError as e:
        raise ValueError(f"Invalid authentication token: {str(e)}")

async def get_user_by_id(db: AsyncSession, user_id: str) -> Optional[User]:
    """Fetches a user from the local database by ID."""
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()

async def sync_user_data(
    db: AsyncSession,
    user_id: str,
    email: str,
    full_name: Optional[str] = None,
    is_anonymous: bool = False,
) -> User:
    """Syncs a user from Neon Auth details to the local app database."""
    user = await get_user_by_id(db, user_id)
    
    if not user:
        # Create a new local user record
        # If anonymous, generate a display name like Scout #A3F2
        display_name = full_name
        if is_anonymous or not full_name:
            short_id = user_id[:4].upper()
            display_name = f"Scout #{short_id}"
            
        user = User(
            id=user_id,
            email=email,
            is_anonymous=is_anonymous,
            display_name=display_name,
            full_name=None if is_anonymous else full_name,
            role="scout", # default role, can be modified by admin
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        db.add(user)
    else:
        # Update existing user email if changed
        user.email = email
        user.updated_at = datetime.utcnow()
        
    await db.flush() # flush to generate state without committing immediately
    return user
