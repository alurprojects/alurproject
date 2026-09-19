import logging
from typing import List, Optional
from langchain_core.prompts import ChatPromptTemplate
from app.core.llm import get_batch_llm, get_fallback_llm

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """You are ALUR's Reflection Agent.
You write calm, non-judgmental, actionable weekly insights when a user has multiple missed tasks on a goal.
You take into account both objective task completion data AND subjective reflections/struggles shared by the user in recent chat conversations.

Rules:
1. Maximum 280 characters.
2. Tone: Calm, restrained, supportive, observational. NEVER scolding, preachy, or using corporate buzzwords.
3. Language: Indonesian by default (match the user context).
4. Plain text only (no emojis, no hashtags, no quotes).
"""

PROMPT = ChatPromptTemplate.from_messages([
    ("system", SYSTEM_PROMPT),
    (
        "human",
        "Goal: {goal_title}\n"
        "Missed tasks count: {missed_count}\n"
        "Examples of missed tasks: {missed_examples}\n"
        "User chat context / reflections: {recent_chat_reflections}\n"
        "Recent completion rate: {completion_rate_str}\n\n"
        "Write a 1-sentence calm observation for the weekly reflection:",
    ),
])


def generate_reflection_insight(
    goal_title: str,
    missed_count: int,
    missed_examples: List[str],
    recent_chat_reflections: Optional[List[str]] = None,
    completion_rate: Optional[float] = None,
) -> str:
    """Generate a 1-sentence calm reflection insight using Gemini/Batch LLM reading combined data."""
    examples_str = ", ".join(missed_examples[:3])
    chat_context_str = "; ".join(recent_chat_reflections[:3]) if recent_chat_reflections else "None recorded"
    completion_str = f"{int(completion_rate * 100)}%" if completion_rate is not None else "N/A"

    input_vars = {
        "goal_title": goal_title,
        "missed_count": str(missed_count),
        "missed_examples": examples_str,
        "recent_chat_reflections": chat_context_str,
        "completion_rate_str": completion_str,
    }

    # Attempt Batch LLM (Gemini primary)
    batch_llm = get_batch_llm()
    if batch_llm:
        try:
            chain = PROMPT | batch_llm
            res = chain.invoke(input_vars)
            content = res.content.strip() if hasattr(res, "content") else str(res).strip()
            if content:
                return content[:280]
        except Exception as e:
            logger.warning(f"Batch reflection LLM failed: {e}")

    # Attempt Fallback LLM (Groq)
    fallback = get_fallback_llm()
    if fallback:
        try:
            chain = PROMPT | fallback
            res = chain.invoke(input_vars)
            content = res.content.strip() if hasattr(res, "content") else str(res).strip()
            if content:
                return content[:280]
        except Exception as e:
            logger.error(f"Fallback reflection LLM failed: {e}")

    # Deterministic fallback template
    return f"Ada {missed_count} task terlewat pada target '{goal_title}'. Pertimbangkan membagi langkah lebih kecil minggu depan."[:280]

