# Instructions for AI Assistants & Agents

## Documentation Source of Truth
- **Single Source of Truth**: All active documentation and technical specifications for the ALUR project are strictly located in:
  `_docs/running/`
- The active documents include:
  1. `_docs/running/PRD.md` — Product requirements, UX specs, core invariants
  2. `_docs/running/DESIGN.md` — Design system, color tokens (`#FAF9F7`, `#111111`, `#1A1A1A`, `#7A7772`, `#DEDBD6`, `#F0EFED`), typography, components
  3. `_docs/running/auth.md` — Authentication specifications, UI layouts, and integration flows
  4. `_docs/running/technical.md` — Tech stack, API contracts, LangGraph multi-agent architecture
  5. `_docs/running/DATABASE.md` — Database schemas, tables, RLS policies, pg_cron jobs
  6. `_docs/running/ENV_GUIDE.md` — Environment variable configurations and client/server isolation
  7. `_docs/running/DEPLOYMENT_GUIDE.md` — Deployment guide (Vercel, Render/VPS migration plans)
  8. `_docs/running/feedback.md` — Audit resolution tracking

## CRITICAL RULES:
1. **NEVER** read from `_docs/archive/` or assume it has active rules. Files in `_docs/archive/` are obsolete historical archives.
2. **DO NOT** create or look for specification files in `_docs/` root. Always use `_docs/running/`.
3. When tracking tasks and implementation plans, use `_docs/task/implementation_plan_260916.md`.
