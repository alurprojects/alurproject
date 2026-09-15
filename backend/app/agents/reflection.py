import logging
from typing import List
from langchain_core.prompts import ChatPromptTemplate
from app.core.llm import get_fallback_llm, get_primary_llm

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """You are ALUR's Reflection Agent.
You write calm, non-judgmental, actionable weekly insights when a user has multiple missed tasks on a goal.

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
        "Goal: {goal_title}\nMissed tasks count: {missed_count}\nExamples of missed tasks: {missed_examples}\n\nWrite a 1-sentence calm observation for the weekly reflection:",
    ),
])


def generate_reflection_insight(
    goal_title: str,
    missed_count: int,
    missed_examples: List[str],
) -> str:
    """Generate a 1-sentence calm reflection insight using LLM."""
    examples_str = ", ".join(missed_examples[:3])
    input_vars = {
        "goal_title": goal_title,
        "missed_count": str(missed_count),
        "missed_examples": examples_str,
    }

    # Attempt Primary LLM
    primary = get_primary_llm()
    if primary:
        try:
            chain = PROMPT | primary
            res = chain.invoke(input_vars)
            content = res.content.strip() if hasattr(res, "content") else str(res).strip()
            if content:
                return content[:280]
        except Exception as e:
            logger.warning(f"Primary reflection LLM failed: {e}")

    # Attempt Fallback LLM
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

    # Fallback template
    return f"Ada {missed_count} task terlewat pada target '{goal_title}'. Pertimbangkan membagi langkah lebih kecil minggu depan."[:280]
