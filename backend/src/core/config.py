from pydantic_settings import BaseSettings
from pydantic import ConfigDict, model_validator
import urllib.parse

class Settings(BaseSettings):
    DATABASE_URL: str
    # Neon Auth managed service base URL
    # e.g. https://ep-xxx.neonauth.c-2.ap-southeast-1.aws.neon.tech/neondb/auth
    NEON_AUTH_BASE_URL: str
    PORT: int = 8000

    @property
    def JWKS_URL(self) -> str:
        """Neon Auth JWKS endpoint — Ed25519 public key for JWT verification."""
        return f"{self.NEON_AUTH_BASE_URL}/.well-known/jwks.json"

    @model_validator(mode="after")
    def transform_database_url(self) -> "Settings":
        """
        Transforms standard postgresql:// URLs into postgresql+asyncpg:// 
        and adapts query parameters (like sslmode -> ssl) to ensure
        compatibility with the asyncpg driver.
        """
        url = self.DATABASE_URL
        if url.startswith("postgresql://"):
            url = "postgresql+asyncpg://" + url[len("postgresql://"):]
        elif url.startswith("postgres://"):
            url = "postgresql+asyncpg://" + url[len("postgres://"):]
            
        parsed = urllib.parse.urlparse(url)
        query_params = urllib.parse.parse_qs(parsed.query)
        
        # Translate sslmode to ssl for asyncpg
        if "sslmode" in query_params:
            val = query_params.pop("sslmode")[0]
            if val in ["require", "verify-ca", "verify-full"]:
                query_params["ssl"] = ["require"]
                
        # Remove unsupported parameters
        query_params.pop("channel_binding", None)
        
        # Reconstruct URL
        new_query = urllib.parse.urlencode(query_params, doseq=True)
        parsed = parsed._replace(query=new_query)
        self.DATABASE_URL = urllib.parse.urlunparse(parsed)
        return self

    model_config = ConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
