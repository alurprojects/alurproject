from functools import lru_cache
from supabase import Client, create_client
from app.core.config import settings


@lru_cache()
def get_supabase_client() -> Client:
    """Returns a cached instance of the Supabase client using the Service Role Key.

    Service role key allows the backend to perform server-controlled operations
    while enforcing business rules and state transitions.
    """
    url = settings.PUBLIC_SUPABASE_URL or ""
    key = settings.SUPABASE_SERVICE_ROLE_KEY or ""
    if not url or not key:
        raise RuntimeError(
            "Supabase credentials missing. Please ensure PUBLIC_SUPABASE_URL and "
            "SUPABASE_SERVICE_ROLE_KEY are configured in environment variables."
        )
    return create_client(
        supabase_url=url,
        supabase_key=key,
    )
