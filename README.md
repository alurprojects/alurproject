<p align="center">
  <h1 align="center">ALUR 🌬️</h1>
  <p align="center"><i>A productivity companion that is actively honest about your capacity—not what you wish it to be.</i></p>
</p>

ALUR is a backend-heavy, multi-agent AI productivity system. It replaces complex dashboards with a minimalist UI and a smart assistant that parses tasks, checks your capacity, and gently warns you against burnout.

**North Star Metric:** *DCDC (Daily Conscious Decision Count)*.

## How It Works

Users interact purely through a simple To-do list and a Chat Room. The LangGraph-powered backend does the heavy lifting: capturing tasks from messy text, managing schedules, and reflecting on missed work.

```text
                    ┌──────────────────────────────────────┐
                    │            User Input                │
                    │   (Chat Room or To-Do Checkbox)      │
                    └──────────────────┬───────────────────┘
                                       │
                    ┌──────────────────▼───────────────────┐
                    │         Companion Agent              │
                    │  (Evaluates intent & sets tone)      │
                    └──────────────────┬───────────────────┘
                                       │
     ┌───────────────┬─────────────────┴─────────────────┬───────────────┐
     ▼               ▼                                   ▼               ▼
┌─────────┐    ┌─────────┐                         ┌──────────┐    ┌──────────┐
│  Task   │    │ Capacity│                         │ Venting/ │    │  Cron /  │
│ Extract │    │  Check  │                         │ Chatting │    │Reflection│
├─────────┤    ├─────────┤                         ├──────────┤    ├──────────┤
│Parses   │    │Reviews  │                         │Adaptive  │    │Nightly & │
│brain-   │    │workload │                         │2-tone    │    │weekly    │
│dump to  │    │and time │                         │reply     │    │insights  │
└─────────┘    └─────────┘                         └──────────┘    └──────────┘
```

## Core Features

| Feature | Description |
|---|---|
| **Hybrid To-Do** | Focus purely on today, with an optional toggle to see the full week. |
| **Chat Room** | Drop random brain-dumps or complain about your day. The AI listens. |
| **Task Extraction** | Write *"Email the boss tomorrow"*, and AI automatically schedules a task. |
| **Capacity Check** | Ask *"What else can I do today?"* to get a realistic assessment of your energy. |
| **Adaptive Tone** | AI speaks honestly (HONEST) by default, but softens (GENTLE) if you show signs of burnout. |
| **Auto-Reflection** | A background cron job safely flags missed tasks and generates weekly insights. |

## Technology Stack

- **Mobile:** Flutter (iOS & Android)
- **Web:** Next.js (To-do & Calendar view only)
- **Backend:** FastAPI (Python)
- **AI Orchestration:** LangGraph & LangChain
- **LLM:** Groq (Real-time) & Gemini 2.0 (Batching/Cron)
- **Database & Auth:** Supabase (PostgreSQL, pg_cron)

## Getting Started

All active documentation is strictly located in the `_docs/running/` folder. 

> ⚠️ **IMPORTANT:** Never read or use files from `_docs/archive/`. 

To understand the system and start developing, read these in order:
1. [`PRD.md`](./_docs/running/PRD.md) - Product requirements and UX rules.
2. [`technical.md`](./_docs/running/technical.md) - API contracts and architecture.
3. [`DATABASE.md`](./_docs/running/DATABASE.md) - Database schema and pg_cron jobs.
4. [`mindmap.md`](./_docs/running/mindmap.md) - Visual system diagrams.
5. [`ENV_GUIDE.md`](./_docs/running/ENV_GUIDE.md) - Local environment setup.

---
*Built to make you productive, but remind you to rest.*
