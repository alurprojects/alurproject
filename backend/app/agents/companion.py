import json
import logging
from typing import Any, Dict, List, Literal, Optional, Tuple
from pydantic import BaseModel, Field
from langchain_core.prompts import ChatPromptTemplate
from app.agents.state import AlurChatState
from app.core.config import settings
from app.core.llm import get_realtime_llm, get_batch_llm

logger = logging.getLogger(__name__)


# --- 4 Persona Modules (Hermes Style) ---
PERSONA_PROMPTS = {
    "HONEST": (
        "Active Persona: HONEST (Default)\n"
        "Characteristics: Direct, grounded, realistic, concise, no false optimism, no emojis. "
        "Focus on practical execution, data-driven daily pacing, and keeping commitments aligned with real capacity."
    ),
    "GENTLE": (
        "Active Persona: GENTLE\n"
        "Characteristics: Compassionate, non-judgmental, warm yet quiet. Gives explicit permission to rest. "
        "De-escalates stress, prioritizes emotional well-being and reducing scope over pushing for productivity."
    ),
    "STRATEGIST": (
        "Active Persona: STRATEGIST\n"
        "Characteristics: Analytical, structured, proactive, high-leverage focus. "
        "Helps sequence complex tasks, identify bottlenecks, batch similar activities, and optimize daily energy."
    ),
    "MINIMALIST": (
        "Active Persona: MINIMALIST\n"
        "Characteristics: Ultra-concise, maximum brevity, 1-2 short sentences or crisp bullet points, zero fluff. "
        "Provides immediate clarity with minimum cognitive load."
    ),
}


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
    active_persona: Literal["HONEST", "GENTLE", "STRATEGIST", "MINIMALIST"] = Field(
        "HONEST",
        description="Active persona module applied to this interaction.",
    )
    response_text: Optional[str] = Field(
        None,
        description=(
            "The AI companion's reply in Indonesian. "
            "For CHAT, REFLECTION, or CAPACITY_QUERY, provide a complete, thoughtful, calm reply matching the active persona. "
            "For TASK_CAPTURE, provide a short 1-line acknowledgment noting the tasks will be captured."
        ),
    )


COMPANION_BASE_PROMPT = """You are ALUR's Companion Agent.
ALUR is a quiet, monochromatic, realistic daily planner and capacity companion for 18-35 year olds.

## Dynamic Active Persona:
{active_persona_prompt}

## 3-Layer Hierarchical Memory:
{hierarchical_memory_str}

## Operational Context:
- Daily capacity target: {daily_capacity_hours} hours.
- Today's date: {today_date}.
- Recent completion rate: {completion_rate_str}.
- Consecutive misses / overdue tasks: {consecutive_misses_str}.
- Recent AI reflection insights: {recent_insights_str}.

## Intent Classification Rules:
- TASK_CAPTURE: User describes tasks to schedule (e.g. 'besok bikin laporan jam 10', 'beli susu').
- REFLECTION: User shares feelings, struggles, fatigue, or reflections (e.g. 'aku capek banget hari ini').
- CAPACITY_QUERY: User asks about remaining hours or workload capacity (e.g. 'masih bisa ngerjain apa hari ini?').
- CHAT: General questions, greetings, or feedback.

Strict Guidelines:
1. Always ground your factual statements in the Hierarchical Memory. Do NOT hallucinate past tasks or events.
2. Tone modulation: Use GENTLE whenever burnout or exhaustion is detected.
3. Respond in natural, thoughtful Indonesian.
"""


def select_active_persona(
    raw_message: str,
    is_burnout_context: bool,
    task_count: int = 0,
    preferred_tone: Optional[str] = None,
) -> Tuple[str, str]:
    """Dynamically routes to one of the 4 persona modules (Honest, Gentle, Strategist, Minimalist)."""
    lower_msg = raw_message.lower().strip()

    # 1. Burnout context strictly routes to GENTLE
    if is_burnout_context:
        return "GENTLE", PERSONA_PROMPTS["GENTLE"]

    # 2. Check for strategist indicators (complex planning, prioritising, many tasks)
    strategist_signals = ["strategi", "prioritas", "urutan", "rencana", "susun", "efektif", "optimal", "roadmap"]
    if task_count >= 4 or any(sig in lower_msg for sig in strategist_signals):
        return "STRATEGIST", PERSONA_PROMPTS["STRATEGIST"]

    # 3. Check for explicit minimalist indicators or very short inquiries
    minimalist_signals = ["singkat", "cepet", "to the point", "quick", "tl;dr", "tldr"]
    if any(sig in lower_msg for sig in minimalist_signals) or (
        len(raw_message) < 15 and not any(k in lower_msg for k in ["kenapa", "gimana", "bagaimana", "saran"])
    ):
        return "MINIMALIST", PERSONA_PROMPTS["MINIMALIST"]

    # 4. Honor preferred tone from Core Profile if specified
    if preferred_tone and preferred_tone.upper() in PERSONA_PROMPTS:
        p = preferred_tone.upper()
        return p, PERSONA_PROMPTS[p]

    return "HONEST", PERSONA_PROMPTS["HONEST"]


def _format_hierarchical_memory(
    core_profile: Optional[Dict[str, Any]],
    short_term_context: List[Dict[str, str]],
    rag_context: Optional[str],
) -> str:
    """Format the 3-Layer Hierarchical Memory into a compact prompt string."""
    # Level 1: Core Profile (~50 tokens)
    profile_summary = core_profile or {"work_style": "Default", "current_stress": "normal"}
    core_str = json.dumps(profile_summary, ensure_ascii=False)

    # Level 2: Short-term Memory (Last 3-5 messages)
    short_term_lines = []
    for h in short_term_context[-5:]:
        role = "User" if h.get("role") == "USER" else "Companion"
        content = h.get("content", "")
        short_term_lines.append(f"{role}: {content}")
    short_term_str = "\n".join(short_term_lines) if short_term_lines else "(Tidak ada percakapan sebelumnya hari ini)"

    # Level 3: Archival Memory (RAG Context)
    archival_str = rag_context if rag_context else "Tidak ada konteks historis yang relevan ditemukan."

    return (
        f"### Level 1: Core User Profile (Long-term Profile):\n{core_str}\n\n"
        f"### Level 2: Short-term Context (Last 3-5 Turns):\n{short_term_str}\n\n"
        f"### Level 3: Archival Memory (RAG Context):\n{archival_str}"
    )


def companion_agent(state: AlurChatState) -> AlurChatState:
    """Companion node: Classifies intent, routes dynamic persona, uses 3-layer memory, and generates response."""
    raw_message = state.get("raw_message", "").strip()
    daily_capacity_hours = state.get("daily_capacity_hours", 8.0)
    today_date = state.get("today_date", "")
    recent_completion = state.get("recent_completion_rate")
    consecutive_misses = state.get("consecutive_misses", 0)
    recent_insights = state.get("recent_insights", [])
    conv_context = state.get("conversation_context", [])
    core_profile = state.get("ai_profile_summary") or {}
    rag_context = state.get("rag_context") or ""

    # Detect burnout keywords in Indonesian
    lower_msg = raw_message.lower()
    burnout_keywords = [
        "capek", "lelah", "burnout", "overwhelmed", "stres", "stress",
        "pusing", "berat", "ga sanggup", "nggak kuat", "tumbang"
    ]
    has_burnout_keyword = any(kw in lower_msg for kw in burnout_keywords)

    # Adaptive Personality evaluation
    has_low_completion = (recent_completion is not None and recent_completion < 0.5)
    has_missed_streak = bool(consecutive_misses and consecutive_misses >= 3)
    has_struggling_insights = any(
        ("terlewat" in ins.lower() or "beban" in ins.lower() or "kecil" in ins.lower())
        for ins in (recent_insights or [])
    )
    is_burnout_context = has_burnout_keyword or has_low_completion or has_missed_streak or has_struggling_insights

    # 1. Dynamic Persona Routing
    preferred_tone = core_profile.get("preferred_tone")
    active_persona, active_persona_prompt = select_active_persona(
        raw_message=raw_message,
        is_burnout_context=is_burnout_context,
        task_count=len(state.get("existing_load_minutes_by_date", {})),
        preferred_tone=preferred_tone,
    )
    expected_tone = "GENTLE" if is_burnout_context else "HONEST"

    recent_insights_str = "; ".join(recent_insights[:2]) if recent_insights else "None recorded"
    hierarchical_memory_str = _format_hierarchical_memory(core_profile, conv_context, rag_context)

    # Try LLM
    llm = get_realtime_llm() or get_batch_llm()
    if llm:
        try:
            sys_prompt = settings.COMPANION_SYSTEM_PROMPT or COMPANION_BASE_PROMPT

            prompt = ChatPromptTemplate.from_messages([
                ("system", sys_prompt),
                ("human", "{message}"),
            ])

            chain = prompt | llm.with_structured_output(CompanionOutput)
            result: Optional[CompanionOutput] = chain.invoke({
                "active_persona_prompt": active_persona_prompt,
                "hierarchical_memory_str": hierarchical_memory_str,
                "daily_capacity_hours": daily_capacity_hours,
                "today_date": today_date,
                "completion_rate_str": f"{int(recent_completion * 100)}%" if recent_completion is not None else "N/A",
                "consecutive_misses_str": str(consecutive_misses or 0),
                "recent_insights_str": recent_insights_str,
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
                    "active_persona": active_persona,
                    "mood_detected": result.overload_signal or ("overload" if is_burnout_context else None),
                    "ai_response": result.response_text or "",
                }
        except Exception as e:
            logger.warning(f"Companion LLM call failed: {e}. Using deterministic fallback.")

    # Deterministic Rule-Based Fallback
    task_keywords = ["harus", "besok", "nanti", "jadwal", "beli", "kerjakan", "tugas", "meeting", "selesaikan", "tolong ingetin", "brain-dump", "buat ", "bikin "]
    is_task = any(kw in lower_msg for kw in task_keywords)

    if is_burnout_context and not is_task:
        return {
            "message_type": "REFLECTION",
            "tone_used": "GENTLE",
            "active_persona": "GENTLE",
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
        if active_persona == "MINIMALIST":
            resp = f"Kapasitas sisa: ~{remaining:.1f} jam (dari {daily_capacity_hours:.1f} jam)."
        elif active_persona == "STRATEGIST":
            resp = f"Kapasitas tersisa ~{remaining:.1f} jam. Rekomendasi: manfaatkan slot ini untuk 1 task prioritas tinggi sebelum sore."
        else:
            resp = (
                f"Kapasitas harianmu: {daily_capacity_hours:.1f} jam. "
                f"Tugas terjadwal: ~{hours_used:.1f} jam. "
                f"Sisa kapasitas fokus realistis: ~{remaining:.1f} jam."
            )
        return {
            "message_type": "CAPACITY_QUERY",
            "tone_used": "HONEST",
            "active_persona": active_persona,
            "mood_detected": None,
            "ai_response": resp,
        }

    if is_task:
        ack = "Tugas dicatat." if active_persona == "MINIMALIST" else "Saya mencatat tugas dari pesanmu dan menjadwalkannya sesuai kapasitas."
        return {
            "message_type": "TASK_CAPTURE",
            "tone_used": expected_tone,
            "active_persona": active_persona,
            "mood_detected": "overload" if is_burnout_context else None,
            "ai_response": ack,
        }

    fallback_chat = "Sip, tercatat." if active_persona == "MINIMALIST" else "Dicatat. Tetap jaga ritme fokus pada satu hal dalam satu waktu."
    return {
        "message_type": "CHAT",
        "tone_used": "HONEST",
        "active_persona": active_persona,
        "mood_detected": None,
        "ai_response": fallback_chat,
    }
