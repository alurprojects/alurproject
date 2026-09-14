# Technical Specification: ALUR

## 1. Stack Overview

| Layer | Teknologi | Alasan |
|---|---|---|
| Mobile App | Flutter (Dart) | Satu kodebase Android/iOS, animasi accordion smooth, native feel |
| Backend API | FastAPI (Python) | Async, cepat, native untuk integrasi LangChain/LangGraph |
| Database | Supabase (PostgreSQL) | Auth + DB + RLS + `pg_cron` dalam satu platform |
| Auth | Supabase Auth (Google OAuth) | Zero password management |
| AI Orchestration | LangGraph | State machine antar-agent (Extractor → Scheduler → Reflection) |
| Agent Runtime | LangChain | Wrapper prompt/LLM call per node |
| LLM Provider | Gemini 1.5 Flash (primary), Groq (fallback/cepat) | Murah, context window besar, cepat untuk task ringan |
| Scheduled Jobs | Supabase `pg_cron` + Edge Functions | Nightly & weekly job tanpa server terpisah |
| Voice-to-Text (Fase 3) | Gemini Audio API atau Whisper API | Brain-dump via suara |

Tidak ada web app, tidak ada hosting frontend terpisah, di scope MVP — sesuai keputusan produk (lihat `PRD.md`).

---

## 2. Arsitektur Sistem

```
Flutter App
   │  REST (HTTPS)
   ▼
FastAPI Backend
   ├── /auth          → proxy ke Supabase Auth
   ├── /tasks          → CRUD langsung ke Postgres
   ├── /brain-dump      → invoke LangGraph pipeline
   └── /insights        → read ai_insights

LangGraph Pipeline (dipanggil dari /brain-dump & cron)
   Extractor Agent → Validate Ambiguity → Scheduler Agent → (Fase 3: Reflection Agent)

Supabase
   ├── Postgres (users, goals, tasks, ai_insights)
   ├── Row Level Security per user_id
   ├── pg_cron: nightly-status-check, weekly-reflection, weekly-recurrence-generator
   └── Auth (Google OAuth)
```

---

## 3. Struktur Repo (Disarankan)

```
alur/
├── mobile/                  # Flutter app
│   ├── lib/
│   │   ├── screens/
│   │   │   ├── onboarding/
│   │   │   ├── weekly_view/     # accordion utama
│   │   │   └── settings/
│   │   ├── widgets/
│   │   │   ├── day_strip.dart
│   │   │   ├── task_row.dart
│   │   │   ├── follow_up_chip.dart
│   │   │   └── brain_dump_button.dart
│   │   ├── models/
│   │   └── services/           # API client
│   └── pubspec.yaml
│
├── backend/                 # FastAPI
│   ├── app/
│   │   ├── api/
│   │   │   ├── tasks.py
│   │   │   ├── brain_dump.py
│   │   │   └── insights.py
│   │   ├── agents/
│   │   │   ├── extractor.py
│   │   │   ├── scheduler.py
│   │   │   ├── reflection.py      # Fase 3
│   │   │   └── graph.py           # LangGraph compile & wiring
│   │   ├── db/
│   │   │   └── models.py
│   │   └── main.py
│   ├── cron/
│   │   ├── nightly_status_check.py
│   │   ├── weekly_reflection.py
│   │   └── weekly_recurrence_generator.py
│   └── requirements.txt
│
└── docs/
    ├── PRD.md
    ├── DESIGN.md
    ├── implementation_plan.md
    └── technical.md
```

---

## 4. API Contract (Ringkas)

| Endpoint | Method | Fungsi |
|---|---|---|
| `/tasks?week=` | GET | Ambil task 7 hari |
| `/tasks` | POST | Tambah task manual |
| `/tasks/{id}` | PATCH | Toggle status DONE/PENDING |
| `/tasks/{id}/clarify` | PATCH | Isi `estimated_minutes` untuk task `(?)` |
| `/tasks/{id}/follow-up` | PATCH | Jawab chip (Lupa/Skip/Pindah) |
| `/tasks/{id}/reschedule` | PATCH | Terima/tolak saran pindah hari |
| `/brain-dump` | POST | Kirim teks/transkrip suara → invoke LangGraph |
| `/insights?surfaced=true` | GET | Ambil insight mingguan yang layak tampil |

Semua endpoint butuh `Authorization: Bearer <supabase_jwt>`, divalidasi via Supabase middleware di FastAPI.

---

## 5. LangGraph Node Detail

```python
# graph.py (pseudocode struktur)
graph = StateGraph(AlurState)
graph.add_node("extractor", extractor_agent)
graph.add_node("validate_ambiguity", validate_ambiguity_fn)   # rule-based, bukan LLM
graph.add_node("scheduler", scheduler_agent)
graph.add_edge("extractor", "validate_ambiguity")
graph.add_edge("validate_ambiguity", "scheduler")
graph.set_entry_point("extractor")
graph.set_finish_point("scheduler")
```

- `validate_ambiguity` sengaja **bukan LLM call** — cukup cek `estimated_minutes is None`. Jangan boroskan token LLM untuk logic yang bisa if-else.
- State (`AlurState`) minimal: `raw_text`, `user_id`, `draft_tasks`, `daily_capacity_hours`, `scheduled_tasks`.
- Fase 3: tambah node `reflection_light` (dipanggil dari cron, bukan dari `/brain-dump`) dan `overload_check` (bagian dari Scheduler, cek total durasi per hari).

---

## 6. Environment & Secrets

```
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
GEMINI_API_KEY=
GROQ_API_KEY=          # fallback
JWT_SECRET=            # untuk validasi token dari Supabase
```

Tidak ada secret AI di sisi Flutter — semua panggilan LLM lewat backend, mobile app tidak pernah pegang API key LLM.

---

## 7. Testing Strategy

| Layer | Pendekatan |
|---|---|
| Extractor Agent | Unit test dengan 15-20 contoh kalimat brain-dump nyata → assert struktur JSON output & `is_ambiguous` benar |
| Scheduler Agent | Unit test kasus overload (total durasi > capacity) → assert saran reschedule muncul |
| Cron jobs | Jalankan manual via endpoint debug (`/debug/run-cron/{job_name}`) sebelum didaftarkan ke `pg_cron` |
| Flutter widgets | Widget test untuk accordion expand/collapse, checkbox toggle, follow-up chip 3 opsi |
| E2E | Minimal 1 flow: brain-dump teks → task muncul di hari yang benar → centang → cek status DB |

---

## 8. Deployment

- **Backend**: Fly.io atau Railway (single instance cukup untuk MVP, scale later)
- **DB/Auth/Cron**: Supabase managed (tidak perlu infra tambahan)
- **Mobile**: Build manual (TestFlight/internal APK) untuk Fase 1-2, App Store/Play Store submission ditunda sampai Fase 3 stabil
- **CI**: GitHub Actions — lint + test on push, deploy backend otomatis ke staging saat merge ke `main`

---

## 9. Observability

- Logging terstruktur (JSON) di setiap agent node — minimal: `user_id`, `node_name`, `input_summary`, `output_summary`, `latency_ms`
- Log ini dipakai buat debug kualitas Extractor Agent (kasus salah parsing) — bukan buat analytics user, sesuai non-goal "tidak ada web dashboard"
- Error dari LLM call (timeout/rate limit) → fallback: task masuk sebagai `is_ambiguous=true` dengan title mentah dari brain-dump, bukan gagal total
