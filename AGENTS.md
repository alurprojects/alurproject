# Instructions for AI Assistants & Agents

## Documentation Source of Truth
- **Single Source of Truth**: All active documentation and technical specifications for the ALUR project are strictly located in:
  `.agents/skills/read-docs/docs/`
- The active documents include:
  1. `.agents/skills/read-docs/docs/PRD.md` — Product requirements, UX specs, core invariants
  2. `.agents/skills/read-docs/docs/DESIGN.md` — Design system, color tokens (`#FAF9F7`, `#111111`, `#1A1A1A`, `#7A7772`, `#DEDBD6`, `#F0EFED`), typography, components
  3. `.agents/skills/read-docs/docs/auth.md` — Authentication specifications, UI layouts, and integration flows
  4. `.agents/skills/read-docs/docs/technical.md` — Tech stack, API contracts, LangGraph multi-agent architecture
  5. `.agents/skills/read-docs/docs/DATABASE.md` — Database schemas, tables, RLS policies, pg_cron jobs
  6. `.agents/skills/read-docs/docs/ENV_GUIDE.md` — Environment variable configurations and client/server isolation
  7. `.agents/skills/read-docs/docs/DEPLOYMENT_GUIDE.md` — Deployment guide (Vercel, Render/VPS migration plans)
  8. `.agents/skills/read-docs/docs/feedback.md` — Audit resolution tracking

## CRITICAL RULES:
1. **NEVER** read from `.agents/skills/read-docs/archive/` or assume it has active rules. Files in `.agents/skills/read-docs/archive/` are obsolete historical archives.
2. **DO NOT** create or look for specification files outside of `.agents/skills/read-docs/docs/`. Always use `.agents/skills/read-docs/docs/`.
3. When tracking tasks and implementation plans, use `.agents/skills/read-docs/docs/implementation_plan.md`.
