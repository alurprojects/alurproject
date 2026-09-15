from datetime import date, datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict


class InsightResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    content: str
    week_of: date
    surfaced: bool = True
    created_at: datetime
