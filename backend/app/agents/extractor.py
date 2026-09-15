import logging
from typing import List, Optional
from pydantic import BaseModel, Field
from langchain_core.prompts import ChatPromptTemplate
from app.agents.state import AlurState, DraftTask
from app.core.llm import get_fallback_llm, get_primary_llm

logger = logging.getLogger(__name__)


class ExtractedItem(BaseModel):
    title: str = Field(..., description="Clean, concise, actionable task title")
    estimated_minutes: Optional[int] = Field(
        None,
        description="Duration in minutes if clearly specified (e.g. '30 menit', '1 jam' -> 60). Null if ambiguous or not stated.",
    )
    preferred_day: Optional[str] = Field(
        None,
        description="Target day if mentioned: 'today', 'tomorrow', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday' (or in Indonesian: 'hari ini', 'besok', 'lusa', 'senin', dsb).",
    )
    recurrence_rule: Optional[str] = Field(
        None,
        description="Recurrence pattern: 'daily', 'weekdays', 'weekends', '2x/week', '3x/week', 'weekly', or null.",
    )


class ExtractedTaskList(BaseModel):
    tasks: List[ExtractedItem] = Field(..., description="List of extracted tasks")


SYSTEM_PROMPT = """You are ALUR's Extractor Agent.
Your job is to parse free-form, messy brain-dump text from the user into actionable task items.

Rules:
1. Extract separate tasks clearly.
2. If the user mentions duration (e.g., "30 menit", "1 jam", "45 mins"), convert to integer minutes. If no clear duration is stated, set estimated_minutes to NULL.
3. If a specific day or timing is mentioned (e.g., "besok", "senin", "tomorrow"), set preferred_day.
4. If a recurring habit is mentioned (e.g., "tiap hari", "setiap senin"), set recurrence_rule.
5. Keep titles concise, punchy, and plain (no emojis, no exclamation marks).
"""

PROMPT = ChatPromptTemplate.from_messages([
    ("system", SYSTEM_PROMPT),
    ("human", "Brain-dump input:\n{raw_text}"),
])


def extractor_agent(state: AlurState) -> AlurState:
    """Extractor node: Parses raw brain-dump text into draft tasks."""
    raw_text = state.get("raw_text", "").strip()
    if not raw_text:
        return {"draft_tasks": []}

    drafts: List[DraftTask] = []

    # Attempt primary LLM (Gemini)
    primary_llm = get_primary_llm()
    if primary_llm:
        try:
            runnable = PROMPT | primary_llm.with_structured_output(ExtractedTaskList)
            result = runnable.invoke({"raw_text": raw_text})
            if result and hasattr(result, "tasks") and result.tasks:
                drafts = [
                    DraftTask(
                        title=item.title,
                        estimated_minutes=item.estimated_minutes,
                        preferred_day=item.preferred_day,
                        recurrence_rule=item.recurrence_rule,
                        is_ambiguous=False,
                    )
                    for item in result.tasks
                ]
                return {"draft_tasks": drafts}
        except Exception as e:
            logger.warning(f"Primary LLM extractor failed: {e}. Trying fallback...")

    # Attempt fallback LLM (Groq)
    fallback_llm = get_fallback_llm()
    if fallback_llm:
        try:
            runnable = PROMPT | fallback_llm.with_structured_output(ExtractedTaskList)
            result = runnable.invoke({"raw_text": raw_text})
            if result and hasattr(result, "tasks") and result.tasks:
                drafts = [
                    DraftTask(
                        title=item.title,
                        estimated_minutes=item.estimated_minutes,
                        preferred_day=item.preferred_day,
                        recurrence_rule=item.recurrence_rule,
                        is_ambiguous=False,
                    )
                    for item in result.tasks
                ]
                return {"draft_tasks": drafts}
        except Exception as e:
            logger.error(f"Fallback LLM extractor failed: {e}")

    # Graceful degradation fallback if LLM calls fail
    logger.info("Using graceful fallback: converting raw text into single ambiguous task.")
    return {
        "draft_tasks": [
            DraftTask(
                title=raw_text,
                estimated_minutes=None,
                preferred_day=None,
                recurrence_rule=None,
                is_ambiguous=True,
            )
        ]
    }
