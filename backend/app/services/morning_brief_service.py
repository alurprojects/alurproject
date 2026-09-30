"""Morning Brief service: generate, persist, and retrieve daily task summaries with RAG grounding."""
import asyncio
from datetime import date, datetime, timedelta, timezone
import logging
from typing import Any, Dict, List, Optional, Tuple
from uuid import UUID

from supabase import Client

from app.core.llm import get_batch_llm, get_realtime_llm
from app.services.rag_service import RAGService

logger = logging.getLogger(__name__)


class MorningBriefService:
    def __init__(self, supabase: Client, rag: RAGService):
        self.supabase = supabase
        self.rag = rag

    def _get_greeting(self, d: date) -> str:
        """Format an Indonesian morning greeting with localized day and date."""
        weekday_names = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"]
        month_names = [
            "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
            "Juli", "Agustus", "September", "Oktober", "November", "Desember"
        ]
        return f"Selamat pagi! Hari {weekday_names[d.weekday()]}, {d.day} {month_names[d.month]} {d.year}."

    def _generate_ai_note(
        self,
        tasks_today: List[Dict[str, Any]],
        missed_tasks: List[Dict[str, Any]],
        capacity_remaining: float,
        rag_context: str,
        user_profile: Optional[Dict[str, Any]] = None,
    ) -> str:
        """Generate grounded AI note for morning brief with strict anti-hallucination rules."""
        llm = get_batch_llm() or get_realtime_llm()
        if llm:
            try:
                from langchain_core.prompts import PromptTemplate

                prompt = PromptTemplate.from_template(
                    "You are ALUR's Companion Agent writing a concise morning brief note (1-2 sentences in Indonesian).\n"
                    "Tone: Calm, realistic, grounded, non-judgmental, encouraging without false cheerfulness.\n\n"
                    "Factual Context (DO NOT hallucinate outside this):\n"
                    "- Tasks Today: {task_count} tasks\n"
                    "- Missed Tasks from Yesterday: {missed_count} tasks\n"
                    "- Remaining Focused Capacity: {capacity_remaining:.1f} hours\n"
                    "- User Core Profile: {user_profile}\n"
                    "- Historical RAG Context:\n{rag_context}\n\n"
                    "Output ONLY the 1-2 sentence note in natural Indonesian:"
                )

                chain = prompt | llm
                res = chain.invoke({
                    "task_count": len(tasks_today),
                    "missed_count": len(missed_tasks),
                    "capacity_remaining": capacity_remaining,
                    "user_profile": user_profile or {},
                    "rag_context": rag_context[:1000] if rag_context else "None",
                })
                text = res.content if hasattr(res, "content") else str(res)
                cleaned = text.strip().replace('"', '')
                if cleaned:
                    return cleaned
            except Exception as e:
                logger.warning(f"Failed to generate LLM morning brief note: {e}")

        # Deterministic Grounded Fallback
        if not tasks_today and not missed_tasks:
            return "Hari ini belum ada tugas terjadwal. Manfaatkan waktu untuk fokus mendalam atau istirahat berkualitas."

        if missed_tasks:
            missed_title = missed_tasks[0].get("title", "tugas kemarin")
            return (
                f"Kemarin ada tugas '{missed_title}' yang terlewat. "
                "Kamu bisa jadwalkan ulang hari ini atau selesaikan jika masih relevan."
            )

        return (
            f"Hari ini ada {len(tasks_today)} tugas terencana dengan estimasi sisa fokus ~{capacity_remaining:.1f} jam. "
            "Tetap jaga ritme satu per satu."
        )

    def generate_brief_sync(self, user_id: UUID, brief_date: Optional[date] = None) -> Dict[str, Any]:
        """Generate structured morning brief for a user (sync)."""
        target_date = brief_date or date.today()

        # 1. Fetch today's tasks
        tasks_res = (
            self.supabase.table("tasks")
            .select("id, title, estimated_minutes, status")
            .eq("user_id", str(user_id))
            .eq("assigned_date", target_date.isoformat())
            .execute()
        )
        tasks_today = tasks_res.data or []

        # 2. Fetch yesterday's missed tasks where missed_follow_up == 'PENDING'
        yesterday = target_date - timedelta(days=1)
        missed_res = (
            self.supabase.table("tasks")
            .select("id, title, estimated_minutes, missed_follow_up")
            .eq("user_id", str(user_id))
            .eq("status", "MISSED")
            .eq("missed_follow_up", "PENDING")
            .gte("assigned_date", yesterday.isoformat())
            .execute()
        )
        missed_tasks = missed_res.data or []

        # 3. Calculate capacity
        user_res = (
            self.supabase.table("users")
            .select("daily_capacity_hours, preferences, ai_profile_summary")
            .eq("id", str(user_id))
            .single()
            .execute()
        )
        user_data = user_res.data or {}
        capacity_hours = float(user_data.get("daily_capacity_hours") or 8.0)

        scheduled_minutes = sum(
            (t.get("estimated_minutes") or 0)
            for t in tasks_today
            if t.get("status") in ("PENDING", "IN_PROGRESS")
        )
        scheduled_hours = scheduled_minutes / 60.0
        remaining_hours = max(0.0, capacity_hours - scheduled_hours)

        # 4. RAG: Retrieve grounded context for AI note
        rag_query = f"ringkasan aktivitas dan kebiasaan tanggal {target_date.isoformat()}"
        try:
            rag_context = self.rag.retrieve_context_sync(user_id=user_id, query=rag_query, top_k=5)
        except Exception as e:
            logger.warning(f"RAG context retrieval failed for brief: {e}")
            rag_context = ""

        # 5. Generate AI Note
        ai_note = self._generate_ai_note(
            tasks_today=tasks_today,
            missed_tasks=missed_tasks,
            capacity_remaining=remaining_hours,
            rag_context=rag_context,
            user_profile=user_data.get("ai_profile_summary"),
        )

        brief_content = {
            "date": target_date.isoformat(),
            "greeting": self._get_greeting(target_date),
            "tasks": [
                {
                    "id": t["id"],
                    "title": t["title"],
                    "estimated_minutes": t.get("estimated_minutes"),
                }
                for t in tasks_today
                if t.get("status") in ("PENDING", "IN_PROGRESS")
            ],
            "missed_tasks": [
                {
                    "id": t["id"],
                    "title": t["title"],
                    "follow_up": t.get("missed_follow_up", "PENDING"),
                }
                for t in missed_tasks
            ],
            "capacity_summary": {
                "total_hours": round(capacity_hours, 1),
                "scheduled_hours": round(scheduled_hours, 1),
                "remaining_hours": round(remaining_hours, 1),
            },
            "ai_note": ai_note,
        }

        # 6. Upsert into morning_briefs
        self.supabase.table("morning_briefs").upsert(
            {
                "user_id": str(user_id),
                "brief_date": target_date.isoformat(),
                "content": brief_content,
            },
            on_conflict="user_id,brief_date",
        ).execute()

        return brief_content

    async def generate_brief(self, user_id: UUID, brief_date: Optional[date] = None) -> Dict[str, Any]:
        """Generate structured morning brief asynchronously."""
        return await asyncio.to_thread(self.generate_brief_sync, user_id, brief_date)

    def get_or_generate_brief_sync(
        self, user_id: UUID, brief_date: Optional[date] = None
    ) -> Tuple[Dict[str, Any], bool]:
        """Fetch existing brief or generate on-demand if not yet present.

        Returns (content_dict, is_newly_generated).
        """
        target_date = brief_date or date.today()

        res = (
            self.supabase.table("morning_briefs")
            .select("id, content, opened_at")
            .eq("user_id", str(user_id))
            .eq("brief_date", target_date.isoformat())
            .execute()
        )

        if res.data and len(res.data) > 0:
            row = res.data[0]
            # Mark opened_at timestamp if first time opened
            if not row.get("opened_at"):
                now_iso = datetime.now(timezone.utc).isoformat()
                self.supabase.table("morning_briefs").update({"opened_at": now_iso}).eq("id", row["id"]).execute()
            return row["content"], False

        # Generate on-demand
        brief = self.generate_brief_sync(user_id=user_id, brief_date=target_date)
        return brief, True

    async def get_or_generate_brief(
        self, user_id: UUID, brief_date: Optional[date] = None
    ) -> Tuple[Dict[str, Any], bool]:
        """Fetch existing brief or generate on-demand asynchronously."""
        return await asyncio.to_thread(self.get_or_generate_brief_sync, user_id, brief_date)
