import logging
from typing import List, Literal, Optional
from pydantic import BaseModel, Field
from langchain_core.prompts import ChatPromptTemplate
from app.agents.state import AlurChatState
from app.core.config import settings
from app.core.llm import get_realtime_llm, get_batch_llm

logger = logging.getLogger(__name__)


class CompanionOutput(BaseModel):
    message_type: Literal["TASK_CAPTURE", "REFLECTION", "CHAT", "CAPACITY_QUERY"] = Field(
        ...,
        description=(
            "TASK_CAPTURE if user inputs tasks/actions to schedule. "
            "REFLECTION if user talks about their struggles, feelings, stress, or day review. "
            "CAPACITY_QUERY if user asks about remaining hours, workload, or what they can fit today. "
            "CHAT for general conversation, questions, or greetings."
        ),
    )
    overload_signal: Optional[str] = Field(
        None,
        description="Signal of overload or burnout (e.g. 'overload', 'burnout', 'exhaustion') or null if normal.",
    )
    suggested_tone: Literal["HONEST", "GENTLE"] = Field(
        "HONEST",
        description="HONEST (default, direct, minimal fluff) or GENTLE (used ONLY when overload/burnout is real).",
    )
    response_text: Optional[str] = Field(
        None,
        description=(
            "The AI companion's reply in Indonesian. "
            "For CHAT, REFLECTION, or CAPACITY_QUERY, provide a complete, thoughtful, calm reply. "
            "For TASK_CAPTURE, provide a short 1-line acknowledgment noting the tasks will be captured."
        ),
    )


COMPANION_SYSTEM_PROMPT = """You are ALUR's Companion Agent.
ALUR is a quiet, monochromatic, realistic daily planner and capacity companion for 18-35 year olds.

Persona Guidelines:
1. Tone Selection (2-Tone System):
   - 'HONEST' (default): Direct, grounded, concise, data-driven, calm. No false optimism, no excessive cheerleading, no emojis.
   - 'GENTLE': Use ONLY when you detect real signals of exhaustion, burnout, or severe overload. Compassionate, non-judgmental, focused on permission to rest.

2. Intent Classification:
   - TASK_CAPTURE: User describes one or more tasks to do, errands, work to schedule (e.g. 'besok bikin laporan jam 10', 'beli susu dan kopi', 'ingatkan review PR').
   - REFLECTION: User shares feelings, struggles, fatigue, or reflects on progress (e.g. 'aku capek banget hari ini', 'kok tugas ga kelar-kelar ya').
   - CAPACITY_QUERY: User asks about remaining time, workload capacity, or feasibility (e.g. 'masih bisa ngerjain apa hari ini?', 'sisa kapasitas berapa?').
   - CHAT: General questions, greetings, feedback, or philosophical thoughts.

3. Context:
   - Daily capacity target: {daily_capacity_hours} hours.
   - Today's date: {today_date}.
   - Recent completion rate: {completion_rate_str}.
   - Consecutive misses / overdue tasks: {consecutive_misses_str}.
   - Recent AI reflection insights: {recent_insights_str}.
   - Recent conversation context:
{conversation_context_str}

Respond in natural, thoughtful Indonesian.
"""


def _format_context(state: AlurChatState) -> str:
    history = state.get("conversation_context", [])
    if not history:
        return "(Tidak ada percakapan sebelumnya hari ini)"
    formatted = []
    for h in history[-6:]:
        role = "User" if h.get("role") == "USER" else "Companion"
        content = h.get("content", "")
        formatted.append(f"{role}: {content}")
    return "\n".join(formatted)


def companion_agent(state: AlurChatState) -> AlurChatState:
    """Companion node: Classifies intent, determines adaptive tone, and generates initial response."""
    raw_message = state.get("raw_message", "").strip()
    daily_capacity_hours = state.get("daily_capacity_hours", 8.0)
    today_date = state.get("today_date", "")
    recent_completion = state.get("recent_completion_rate")
    consecutive_misses = state.get("consecutive_misses", 0)
    recent_insights = state.get("recent_insights", [])

    # Detect burnout keywords in Indonesian
    lower_msg = raw_message.lower()
    burnout_keywords = ["capek", "lelah", "burnout", "overwhelmed", "stres", "stress", "pusing", "berat", "ga sanggup", "nggak kuat", "tumbang"]
    has_burnout_keyword = any(kw in lower_msg for kw in burnout_keywords)

    # Adaptive Personality evaluation:
    # 1. Direct verbal signals of burnout/exhaustion
    # 2. Low completion rate (< 50%) or multiple consecutive misses (>= 3)
    # 3. Recent reflection insights indicating recurring task overloads
    has_low_completion = (recent_completion is not None and recent_completion < 0.5)
    has_missed_streak = bool(consecutive_misses and consecutive_misses >= 3)
    has_struggling_insights = any(
        ("terlewat" in ins.lower() or "beban" in ins.lower() or "kecil" in ins.lower())
        for ins in (recent_insights or [])
    )
    is_burnout_context = has_burnout_keyword or has_low_completion or has_missed_streak or has_struggling_insights
    expected_tone = "GENTLE" if is_burnout_context else "HONEST"

    recent_insights_str = "; ".join(recent_insights[:2]) if recent_insights else "None recorded"

    # Try LLM
    llm = get_realtime_llm() or get_batch_llm()
    if llm:
        try:
            context_str = _format_context(state)
            sys_prompt = settings.COMPANION_SYSTEM_PROMPT or COMPANION_SYSTEM_PROMPT

            prompt = ChatPromptTemplate.from_messages([
                ("system", sys_prompt),
                ("human", "{message}"),
            ])

            chain = prompt | llm.with_structured_output(CompanionOutput)
            result: Optional[CompanionOutput] = chain.invoke({
                "daily_capacity_hours": daily_capacity_hours,
                "today_date": today_date,
                "completion_rate_str": f"{int(recent_completion * 100)}%" if recent_completion is not None else "N/A",
                "consecutive_misses_str": str(consecutive_misses or 0),
                "recent_insights_str": recent_insights_str,
                "conversation_context_str": context_str,
                "message": raw_message,
            })

            if result:
                msg_type = result.message_type
                tone = result.suggested_tone
                if is_burnout_context:
                    tone = "GENTLE"

                return {
                    "message_type": msg_type,
                    "tone_used": tone,
                    "mood_detected": result.overload_signal or ("overload" if is_burnout_context else None),
                    "ai_response": result.response_text or "",
                }
        except Exception as e:
            logger.warning(f"Companion LLM call failed: {e}. Using deterministic fallback.")

    # Deterministic Rule-Based Fallback
    # Check if task capture
    task_keywords = ["harus", "besok", "nanti", "jadwal", "beli", "kerjakan", "tugas", "meeting", "selesaikan", "tolong ingetin", "brain-dump", "buat ", "bikin "]
    is_task = any(kw in lower_msg for kw in task_keywords)

    if is_burnout_context and not is_task:
        return {
            "message_type": "REFLECTION",
            "tone_used": "GENTLE",
            "mood_detected": "overload",
            "ai_response": (
                "Wajar jika merasa overload. Ingat prinsip ALUR: kapasitas harianmu bukan apa yang "
                "kamu harapkan, tapi apa yang realistis untuk tubuh dan pikiranmu. "
                "Mari kita pilah 1 hal terpenting saja untuk hari ini, sisanya kita geser."
            ),
        }

    if "kapasitas" in lower_msg or "sisa" in lower_msg or "cek" in lower_msg:
        existing_minutes = sum(state.get("existing_load_minutes_by_date", {}).values())
        hours_used = existing_minutes / 60.0
        remaining = max(0.0, daily_capacity_hours - hours_used)
        return {
            "message_type": "CAPACITY_QUERY",
            "tone_used": "HONEST",
            "mood_detected": None,
            "ai_response": (
                f"Kapasitas harianmu: {daily_capacity_hours:.1f} jam. "
                f"Tugas terjadwal: ~{hours_used:.1f} jam. "
                f"Sisa kapasitas fokus realistis: ~{remaining:.1f} jam."
            ),
        }

    if is_task:
        return {
            "message_type": "TASK_CAPTURE",
            "tone_used": expected_tone,
            "mood_detected": "overload" if is_burnout_context else None,
            "ai_response": "Saya mencatat tugas dari pesanmu dan menjadwalkannya sesuai kapasitas.",
        }

    return {
        "message_type": "CHAT",
        "tone_used": "HONEST",
        "mood_detected": None,
        "ai_response": "Dicatat. Tetap jaga ritme fokus pada satu hal dalam satu waktu.",
    }
