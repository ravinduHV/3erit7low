import time
from datetime import datetime
from typing import Dict, Any, Optional

import jwt  # PyJWT
from jwt import PyJWKClient

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from src.core.config import settings
from src.db.models import User

# ── JWKS key caching ─────────────────────────────────────────────────────────
# PyJWKClient fetches and caches public keys from the Neon Auth JWKS endpoint.
# We recreate it every hour so that key rotations are picked up automatically.

_jwks_client: Optional[PyJWKClient] = None
_jwks_fetched_at: float = 0.0
_JWKS_TTL_SECONDS = 3600  # refresh every hour


def _get_jwks_client() -> PyJWKClient:
    """Returns a cached PyJWKClient, refreshing if the TTL has expired."""
    global _jwks_client, _jwks_fetched_at
    now = time.monotonic()
    if _jwks_client is None or (now - _jwks_fetched_at) > _JWKS_TTL_SECONDS:
        _jwks_client = PyJWKClient(settings.JWKS_URL, cache_jwk_set=True, lifespan=_JWKS_TTL_SECONDS)
        _jwks_fetched_at = now
    return _jwks_client


# ── Token decoding ────────────────────────────────────────────────────────────

def decode_token(token: str) -> Dict[str, Any]:
    """
    Verifies a Neon Auth JWT using the JWKS public key (EdDSA / Ed25519).

    Neon Auth managed service signs tokens with EdDSA (Ed25519 curve).
    The public key is fetched from {NEON_AUTH_BASE_URL}/.well-known/jwks.json
    and cached for 1 hour to avoid per-request network calls.

    Returns the decoded payload dict on success.
    Raises ValueError on any validation failure.
    """
    try:
        jwks_client = _get_jwks_client()
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["EdDSA"],
            options={"verify_aud": False},  # Neon Auth JWTs may omit the aud claim
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise ValueError("Token has expired")
    except jwt.InvalidTokenError as e:
        raise ValueError(f"Invalid authentication token: {str(e)}")
    except Exception as e:
        # Catches JWKS fetch failures, key not found, etc.
        raise ValueError(f"Token validation failed: {str(e)}")


# ── User DB helpers ───────────────────────────────────────────────────────────

async def get_user_by_id(db: AsyncSession, user_id: str) -> Optional[User]:
    """Fetches a user from the local app database by their Neon Auth UUID."""
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


async def sync_user_data(
    db: AsyncSession,
    user_id: str,
    email: str,
    full_name: Optional[str] = None,
    is_anonymous: bool = False,
) -> User:
    """
    Upserts a user from Neon Auth into the local app users table.

    - On first sync: creates a new User row with default role='scout'.
    - On subsequent syncs: updates the email (in case it changed in Neon Auth).
    - Anonymous users get an auto-generated display name like 'Scout #A3F2'.
    """
    user = await get_user_by_id(db, user_id)

    if not user:
        # Generate display name: use full_name for known users, auto-code for anonymous
        if is_anonymous or not full_name:
            short_id = user_id[:4].upper()
            display_name = f"Scout #{short_id}"
        else:
            display_name = full_name

        user = User(
            id=user_id,
            email=email,
            is_anonymous=is_anonymous,
            display_name=display_name,
            full_name=None if is_anonymous else full_name,
            role="scout",  # default — admin can promote via admin panel
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(user)
    else:
        # User already exists — just keep email in sync
        user.email = email
        user.updated_at = datetime.utcnow()

    await db.flush()
    return user
