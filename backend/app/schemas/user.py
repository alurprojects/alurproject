from typing import Any, Dict, List, Optional
from uuid import UUID
from pydantic import BaseModel, Field


class FixedBlock(BaseModel):
    label: Optional[str] = Field(None, max_length=100)
    days: List[int] = Field(
        default_factory=list,
        description="0=Senin .. 6=Minggu. Kosong = berlaku semua hari.",
    )
    start: str = Field(..., description="Jam mulai HH:MM")
    end: str = Field(..., description="Jam selesai HH:MM")


class PreferencesUpdate(BaseModel):
    daily_capacity_hours: Optional[float] = Field(None, gt=0, le=24)
    timezone: Optional[str] = Field(None, max_length=64)
    fixed_blocks: Optional[List[FixedBlock]] = None
    todo_default_view: Optional[str] = Field(None, pattern="^(daily|weekly)$")
    onboarding_completed_at: Optional[str] = Field(
        None, description="ISO timestamp, atau null untuk reset onboarding."
    )
    extra: Optional[Dict[str, Any]] = Field(
        None, description="Key preferences lain yang ingin disimpan apa adanya."
    )
