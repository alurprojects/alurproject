from pydantic import BaseModel, Field


class BrainDumpRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=5000, description="Raw brain-dump text from user")
