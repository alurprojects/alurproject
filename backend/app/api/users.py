from typing import Any, Dict
from uuid import UUID
from fastapi import APIRouter, Depends
from supabase import Client

from app.api.deps import get_current_user_id
from app.core.supabase import get_supabase_client
from app.schemas.user import PreferencesUpdate
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["users"])


def _service(supabase: Client = Depends(get_supabase_client)) -> UserService:
    return UserService(supabase)


@router.get("/me", response_model=Dict[str, Any])
def get_me(
    user_id: UUID = Depends(get_current_user_id),
    service: UserService = Depends(_service),
) -> Dict[str, Any]:
    return service.get_me(user_id=user_id)


@router.patch("/me/preferences", response_model=Dict[str, Any])
def update_preferences(
    patch_in: PreferencesUpdate,
    user_id: UUID = Depends(get_current_user_id),
    service: UserService = Depends(_service),
) -> Dict[str, Any]:
    return service.update_preferences(user_id=user_id, patch_in=patch_in)
