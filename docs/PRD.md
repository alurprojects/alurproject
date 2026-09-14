# ALUR — PRD

**Visi**: Frontend sesederhana kertas coretan. Backend secanggih asisten pribadi otonom. North Star: **DCDC** (task dipilih sadar, bukan sekadar selesai).

**Dihapus permanen**: Harada Method, 8 Pilar/64-Grid, chat sebagai interface utama, multi-tab, web dashboard, gamifikasi, auto-reschedule tanpa izin user.

---

## UI

```
MONDAY
☑ 5km run
☐ Read 10 pages
☐ Walk the dog (?)              ← durasi/waktu belum jelas
💬 "Riset desain" kemarin skip — lupa atau emang skip?
   [Lupa, udah dikerjain] [Emang skip] [Pindah ke hari ini]

[+ Add a new task...]  [🎙 Brain-dump]
TUESDAY   ── collapsed
WEDNESDAY ── collapsed
```

- Hari aktif expanded, lainnya collapsed strip.
- `(?)` → tap → input inline durasi/waktu.
- Task miss tetap di tempat (histori jujur), style redup. Reschedule butuh approval user, tidak otomatis.
- Follow-up chip cuma untuk task goal-linked atau recurring — bukan semua task miss.
- Dark/light mode wajib sejak awal. Tidak ada dashboard/grafik di v1.

---

## Data Model

```sql
users     (id, email, name, timezone, daily_capacity_hours, preferences json)
goals     (id, user_id, title, status: ACTIVE|DONE|ARCHIVED)
tasks     (id, user_id, goal_id?, title, assigned_date,
           estimated_minutes?, recurrence_rule?,
           status: PENDING|DONE|MISSED,
           is_ambiguous, ai_generated, source: MANUAL|BRAIN_DUMP,
           missed_follow_up: NONE|PENDING|FORGOT|SKIPPED|RESCHEDULED)
ai_insights (id, user_id, content, week_of, surfaced)
```

Habit = task dengan `recurrence_rule` terisi. Tidak ada tabel terpisah.

---

## Arsitektur Agent

Stack: **LangGraph** (orchestration) + **LangChain** + LLM (Gemini/Groq) + Supabase (`pg_cron`).

| Agent | Trigger | Tugas |
|---|---|---|
| **Extractor** | Real-time (brain-dump) | Teks/suara bebas → list task terstruktur, flag `is_ambiguous` |
| **Scheduler** | Setelah Extractor / cron mingguan | Set `assigned_date`, cek capacity harian (invisible), saran reschedule (opt-in) |
| **Reflection** | Cron nightly + weekly | Tandai `MISSED`, pilih task yang perlu `missed_follow_up`, cari pola mingguan → `ai_insights` |
| **Orchestrator** | Selalu aktif | Gatekeeper: kapan follow-up/insight/saran reschedule boleh tampil ke UI. Default diam. |

**Cron jobs**: `nightly-status-check` (00:00/timezone), `weekly-reflection` (Minggu malam), `weekly-recurrence-generator` (Minggu malam).

---

## Flow Inti

1. **Brain-dump** → Extractor → Scheduler → task masuk DB → UI refresh.
2. **Eksekusi harian** → centang task, tidak menyentuh AI sama sekali.
3. **Nightly** → tandai MISSED → Reflection pilih mana yang perlu follow-up.
4. **Follow-up** → user jawab chip → status/`missed_follow_up` terupdate.
5. **Weekly** → insight pola + generate task recurring minggu depan.

Diagram detail: `alur_end_to_end_flow.mermaid`, `alur_agent_sequence.mermaid`.

---

## Fase

| Fase | Scope |
|---|---|
| 1 | UI accordion + manual add/centang. Tanpa AI. |
| 2 | Extractor + Scheduler + follow-up, diorkestrasi via LangGraph (sekaligus latihan orchestration). |
| 3 | Reflection Agent + semua cron + saran reschedule + voice-to-text. |

## Non-Goals
Harada/8-Pilar, chat-first, multi-tab, web dashboard, gamifikasi, auto-reschedule diam-diam.
