# Peta Konsep dan Alur Sistem ALUR

> **Versi:** 2026-09-30 v2 — Update: integrasi MoSCoW (13/9/8/9), Morning Brief & RAG selesai, `track-progress/` live
> **Sumber:** `PRD.md` · `technical.md` · `DATABASE.md` · `DESIGN.md` · `MOSCOW_FEATURES.md` · `exec/2026-09-28_exec-morning-brief-rag.md`

Dokumen ini memuat rangkuman visual ALUR: **apa yang dibangun, bentuknya seperti apa, bagaimana data mengalir**, dan **bagaimana progres dilacak**.

---

## 0. Ringkasan: Apa yang Kita Bangun?

**ALUR** = *productivity companion yang jujur tentang kapasitas kamu* — bukan to-do list yang bilang "kamu pasti bisa".

| Pertanyaan | Jawaban |
| :--- | :--- |
| **Masalah P1** | Bingung prioritas tiap pagi → **Morning Brief Top 3** + **Capacity Warning** |
| **Masalah P2** | To-do jarang tuntas → **Nightly MISSED** + **Saran Reschedule 1-tap** (dengan persetujuan, bukan auto-pindah) |
| **Masalah P3** | Tidak paham pola sendiri → **Insight Mingguan naratif** (combined `tasks` + `conversation_logs`) |
| **Bentuk Mobile** | Flutter — 4 tab: **To-do** (Daily Focus/Weekly) · **Chat Room** (brain-dump & curhat) · **Calendar** (time-block read-only) · **Profile** (goals & retensi) |
| **Bentuk Web** | Next.js — **WeekGrid 7 kolom + Someday Drawer + BrainDumpModal + TaskEditModal**, scope v1: To-do + Calendar saja (`PRD §3.6`) |
| **Bentuk Backend** | FastAPI + LangGraph (5 agent) + Supabase (Postgres + RLS + `pg_cron` + pgvector) |
| **Prinsip** | *Invisible Complexity* — UI sesederhana kertas, kecerdasan di backend. *FORGOT vs SKIPPED* — bedakan lupa vs sengaja. |

**Status 2026-09-30:** R2 (Prioritas Pagi) selesai — Mobile + Backend live, Web masih `localStorage` mock. Rekomendasi rilis: **Mobile dulu**, Web parity setelah API stabil.

---

## 1. Mindmap: Struktur Fitur, Integrasi, LLM & Progres

```mermaid
flowchart LR
    Root["ALUR Project"]

    Feat["Core Features (MoSCoW)"]
    Root --> Feat
    Feat --> F1["M2 Hybrid To-do (Daily/Weekly) — Must"]
    Feat --> F2["M4/M12 Chat Room (Brain-dump & Capacity Chat) — Must"]
    Feat --> F3["M5 Morning Brief Top 3 — Must ✅"]
    Feat --> F4["M8 Reschedule + M9 FORGOT/SKIPPED — Must (R3)"]
    Feat --> F5["M10 Insight Mingguan — Must (R3)"]
    Feat --> F6["S3 Calendar Time-block · S4 Goals · S9 Web Parity — Should"]
    Feat --> F7["C2 Voice · C5 RAG pgvector ✅ · C4 Hierarchical Memory ✅ — Could"]

    Plat["Platform Integration"]
    Root --> Plat
    Plat --> P1["Mobile (Flutter) — 4-tab, MorningBriefBanner ✅"]
    Plat --> P2["Web (Next.js) — WeekGrid/Someday/BrainDump ⚠️ localStorage mock"]
    Plat --> P3["Backend (FastAPI + LangGraph) ✅"]
    Plat --> P4["DB, Auth, pg_cron, pgvector (Supabase) ✅ 012-016"]

    AI["AI & LLM Orchestration"]
    Root --> AI
    AI --> A1["LangGraph State Machine"]
    AI --> A2["Companion Agent — Hermes 4-persona + 3-layer memory ✅"]
    AI --> A3["Extractor Agent (Task Parsing)"]
    AI --> A4["Scheduler Agent (Capacity + task_suggestions)"]
    AI --> A5["Reflection Agent (combined tasks+logs → ai_insights)"]
    AI --> A6["Embedding/RAG Service (Gemini text-embedding-004, vector 768) ✅"]
    AI --> A7["MorningBriefService (cron hourly + RAG ai_note) ✅"]

    Gov["Governance & Tracking — NEW v2"]
    Root --> Gov
    Gov --> G1["MOSCOW_FEATURES.md — 13/9/8/9 (SSOT)"]
    Gov --> G2["exec/ — checklist Phase 1-6 ✅"]
    Gov --> G3["track-progress/YYYY-MM-DD.md — daily log (trigger: exec/MoSCoW/spec/milestone, BUKAN per git push)"]
    Gov --> G4["AGENTS.md Rule 5 — automation contract"]
```

---

## 2. Flowchart: Pipeline Data & Proses Sistem (Updated v2)

Menambahkan **RAG retrieval**, **Hierarchical Memory**, dan **Morning Brief cron** yang selesai di R2.

```mermaid
flowchart TD
    User(["User"])
    Client["Client App<br/>(Mobile 4-tab / Web WeekGrid)"]
    API["FastAPI Backend"]
    DB[("Supabase DB<br/>tasks, conversation_logs,<br/>embeddings, morning_briefs,<br/>ai_insights")]
    Cron["pg_cron (Supabase)"]
    LLM["LLM<br/>Groq (real-time) / Gemini 2.0 Flash (batch)<br/>+ Gemini Embedding 004"]

    subgraph LG ["LangGraph AI Pipeline"]
        direction TB
        Comp["Companion Agent<br/>Hermes: 4-persona router<br/>3-layer memory"]
        Intent{"Intent Routing"}
        Ext["Extractor Agent"]
        Sched["Scheduler Agent"]
        Refl["Reflection Agent"]
        Rag["RAG Service<br/>retrieve_context +<br/>grounded_prompt"]
        Brief["MorningBriefService<br/>capacity + RAG ai_note"]
    end

    %% Real-time: Chat / Brain-dump
    User -->|"1. Brain-dump / curhat / capacity query"| Client
    Client -->|"2. POST /chat/message"| API
    API -->|"3. Init AlurChatState"| Comp
    DB -.->|"4a. Core Profile JSON (~50 tok) +<br/>last 3-5 msgs (short-term)"| Comp
    Rag -.->|"4b. Archival memory (pgvector match_embeddings)"| Comp
    Rag <--> LLM
    Comp -->|"5. Classify intent + tone HONEST/GENTLE"| Intent
    Intent -->|"TASK_CAPTURE"| Ext
    Intent -->|"REFLECTION / CHAT / CAPACITY_QUERY"| API
    Ext -->|"6. Parse → draft_tasks"| Sched
    Sched -->|"7. Cek daily_capacity_hours,<br/>buat task_suggestions jika overload"| API
    API -->|"8. Simpan tasks / conversation_logs<br/>+ upsert embeddings (hook)"| DB
    DB <--> LLM
    API -->|"9. Response + state baru"| Client
    Client -->|"10. Update UI (banner/chip/insight)"| User

    %% Cron background
    Cron -->|"A. Nightly 00:00/timezone"| API
    API -->|"POST /internal/cron/* (X-Cron-Secret)"| Refl
    DB -.->|"B. Batch fetch tasks+logs"| Refl
    Refl -->|"C. Flag MISSED + ai_insights"| DB

    Cron -->|"D. Hourly — morning-brief-generator"| API
    API --> Brief
    Brief -->|"E. Generate brief per reminder_hour"| DB
    Client -.->|"F. GET /morning-brief (on-demand fallback)"| Brief
```

**Catatan v2:** Garis `Rag` dan `Brief` adalah **baru** — keduanya sudah live (`embedding_service.py`, `rag_service.py`, `morning_brief_service.py`, migrasi `012–016`).

---

## 3. Alur Penggunaan Fitur (User Journey) — Tetap, + Morning Brief

### A. Morning Brief (NEW — Jawaban P1)

```mermaid
sequenceDiagram
    actor User
    participant Mobile as Mobile To-do (Daily Focus)
    participant API as FastAPI
    participant Brief as MorningBriefService
    participant DB as Supabase

    Note over Cron,DB: Cron hourly cek reminder_hour
    Cron->>Brief: POST /internal/cron/morning-brief
    Brief->>DB: Hitung kapasitas + query pending/missed + RAG ai_note
    Brief->>DB: Upsert morning_briefs (JSONB)
    User->>Mobile: Buka app pagi
    Mobile->>API: GET /morning-brief?date=today
    API->>DB: Ambil brief (atau generate on-demand)
    API-->>Mobile: Top 3 + alasan + ai_note + warning jika overload
    Mobile-->>User: Banner di puncak Daily Focus [Edit][Tambah][Cerita ke AI]
```

### B. To-Do (Eksekusi Harian & Mingguan)

```mermaid
flowchart LR
    Start([Buka Tab To-do]) --> View[Tampilan 'Daily Focus' / Hari Ini]
    View --> Brief{ MorningBriefBanner? }
    Brief -->|Ada| BriefAct[Lihat Top 3 + Warning]
    Brief --> Swipe[Swipe Kiri/Kanan]
    Swipe --> ViewOther[Lihat Tugas Hari Lain]
    View --> Check[Centang Checkbox]
    Check --> Done((Tugas Selesai))
    View --> Add[Tap '+ Add Task']
    Add --> Manual[Ketik & Tambah Manual]
    View --> Toggle[Toggle 'Weekly Overview']
    Toggle --> Expand[Lihat Jadwal Penuh Senin-Minggu]
```

### C. Brain-dump (Ekstraksi Tugas Otomatis)

```mermaid
sequenceDiagram
    actor User
    participant App as Tab Chat Room
    participant AI as AI (Companion & Extractor)
    
    User->>App: "Besok sore aku harus email bos, trus beli cat buat pagar"
    App->>AI: Menganalisis pesan (Sistem mendeteksi 2 pekerjaan)
    AI->>AI: Memecah jadi "Email bos" (besok) & "Beli cat" (hari ini)
    AI-->>App: Balas: "Siap! 2 tugas baru sudah masuk ke daftar To-Do kamu."
    App-->>User: Tampilkan pesan + Otomatis update daftar To-Do
```

### D. Curhat & Cek Kapasitas Beban Kerja

```mermaid
sequenceDiagram
    actor User
    participant App as Tab Chat Room
    participant AI as AI (Companion Agent)
    
    User->>App: "Aku capek banget nih, apalagi sih kerjaan yang sisa hari ini?"
    App->>AI: Membaca teks & mengecek beban kerja minggu ini
    AI->>AI: Mendeteksi indikasi 'burnout' (Beralih ke mode bicara GENTLE)
    AI-->>App: Balas: "Hari ini masih sisa 3 tugas, tapi kamu kelihatan lelah. Mau aku undur semuanya ke besok aja biar kamu bisa istirahat?"
    App-->>User: Menampilkan tawaran reschedule & simpati AI
```

### E. Evaluasi Otomatis (Review Malam & Mingguan) + RAG Memory

```mermaid
flowchart TD
    Start([Pukul 00:00 - Setiap Malam]) --> Cek[Sistem Mengecek Tugas Hari Ini]
    Cek --> Sisa[Ada Tugas Belum Dicentang]
    Sisa --> Missed[Tugas Ditandai 'Terlewat' / MISSED]
    Missed --> EmbedMiss[Upsert embedding untuk MISSED]
    Missed --> Ask[Besoknya AI bertanya di Chat: 'Kemarin lupa atau sengaja dilewati?']

    Start2([Minggu Malam - Tiap Pekan]) --> Refl[Reflection Agent:<br/>Batch fetch tasks+logs]
    Refl --> Combine[Membaca Pola: MISSED + conversation_logs<br/>+ RAG archival memory]
    Combine --> Insight[Hasilkan ai_insights<br/>WEEKLY_REFLECTION / PATTERN_DETECTION / CAPACITY_WARNING]

    Start3([Nightly juga]) --> Condenser[Background Memory Condenser]
    Condenser --> Profile[Update users.ai_profile_summary JSON<br/>~50 token → dipakai Companion besok]
```

---

## 4. Roadmap & Kerangka Kerja (Selaras MOSCOW_FEATURES.md)

```mermaid
flowchart LR
    R1["R1 — Fondasi<br/>(Fase 1 UI Core)<br/>M1 Auth · M2 Hybrid To-do<br/>M3 CRUD · M13 RLS · S3 Calendar"] --> R2
    R2["R2 — Prioritas Pagi ✅<br/>(Fase 2 Chat+LangGraph)<br/>M4 Brain-dump · M5 Morning Brief<br/>M6 Capacity · M11 Orchestrator<br/>M12 Capacity Chat · S1 2-Tone"] --> R3
    R3["R3 — Reschedule & Insight<br/>(Fase 3 Otonomi)<br/>M7 Nightly MISSED<br/>M8 Reschedule 1-tap<br/>M9 FORGOT/SKIPPED<br/>M10 Insight Mingguan"] --> R4
    R4["R4 — Penyempurnaan<br/>S2 Batch Reschedule · S5 Recurrence<br/>S6 Push · S8 Retensi Chat<br/>+ C1-C8 bertahap"] --> TB["Tahap B<br/>C1 GCal read-only"]

    style R2 fill:#111111,stroke:#DEDBD6,color:#FAF9F7
```

Rekomendasi rilis (`track-progress/2026-09-30.md`): **Mobile R2 dulu** → Web parity (S9) setelah API stabil → R3 bersamaan untuk kedua platform.

---

## 5. Kerangka Tracking Progres (NEW v2)

```mermaid
flowchart TD
    Trigger{"Event terjadi?"}
    Trigger -->|"exec/ checklist dicentang"| Log
    Trigger -->|"MOSCOW_FEATURES.md berubah"| Log
    Trigger -->|"Spec inti berubah<br/>(PRD/technical/DATABASE/plans)"| Log
    Trigger -->|"Milestone tercapai<br/>(deploy/QA)"| Log
    Trigger -->|"Hanya git push<br/>tanpa (a)-(d)"| Skip["Tidak perlu log<br/>(bukan progress fitur)"]

    Log["Update track-progress/YYYY-MM-DD.md<br/>(append hari yang sama)"]
    Log --> Content["Isi: Ringkasan · Evaluasi MoSCoW<br/>Keputusan Web-vs-Mobile<br/>Perubahan Fitur · Next Step"]

    Content --> Rule["AGENTS.md Rule 5<br/>Automation Contract:<br/>agent yang ubah exec/plans/MoSCoW<br/>WAJIB update log hari ini"]
```

> **Bukan per `git push`.** Commit ≠ progress fitur. Log ditrigger saat checklist/exec, prioritas MoSCoW, spec, atau milestone berubah — jika 1 hari ada banyak perubahan, cukup 1 file hari itu yang di-append.

---

**Catatan Penting:**
Arsitektur tetap **Backend-Heavy & Simple Frontend** — orkestrasi state & kecerdasan sepenuhnya di multi-agent LangGraph. Frontend (Mobile & Web) sesederhana kertas, backend secanggih tim asisten pribadi otonom. Palet `#FAF9F7` / `#111111` / `#F0EFED`, Inter Black 900 uppercase, no shadows (`DESIGN.md` CONST-01–04).
