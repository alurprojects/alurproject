from functools import lru_cache
from supabase import Client, create_client
from app.core.config import settings


@lru_cache()
def get_supabase_client() -> Client:
    """Returns a cached instance of the Supabase client using the Service Role Key.

    Service role key allows the backend to perform server-controlled operations
    while enforcing business rules and state transitions.
    """
    return create_client(
        supabase_url=settings.PUBLIC_SUPABASE_URL,
        supabase_key=settings.SUPABASE_SERVICE_ROLE_KEY,
    )
