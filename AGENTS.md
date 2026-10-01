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
  9. `.agents/skills/read-docs/docs/MOSCOW_FEATURES.md` — MoSCoW feature prioritization (13 Must / 9 Should / 8 Could / 9 Won't) — Single Source of Truth for feature priority
  10. `.agents/skills/read-docs/docs/track-progress/YYYY-MM-DD.md` — Daily progress logs (auto-tracked)

## CRITICAL RULES:
1. **NEVER** read from `.agents/skills/read-docs/archive/` or assume it has active rules. Files in `.agents/skills/read-docs/archive/` are obsolete historical archives.
2. **DO NOT** create or look for specification files outside of `.agents/skills/read-docs/docs/`. Always use `.agents/skills/read-docs/docs/`.
3. **Implementation Plans (`/plan` command)**:
   - **Directory**: Store all implementation plans in `.agents/skills/read-docs/docs/plans/`.
   - **File Naming**: Use a concise format with date and short feature name: `YYYY-MM-DD_nama-fitur.md` (e.g., `2026-09-28_auth-ui.md`).
   - **Single-File Versioning**: Use **ONLY ONE** file per feature. Do NOT generate new files for every revision or iteration.
   - **Changelog System**: If a revision is made, update the main content directly and append the revision history to a `# Changelog` section at the bottom of the same document for readability.

4. **Execution Plans (Breakdown)**:
   - **Directory**: Store execution checklists in `.agents/skills/read-docs/docs/exec/`.
   - **File Naming**: Use format `YYYY-MM-DD_exec-nama-fitur.md`.
   - **Format**: Must use modular sections (phases) and actionable markdown checklists (`- [ ]`) for progress tracking.

5. **Daily Progress Tracking (`track-progress/`)**:
   - **Directory**: `.agents/skills/read-docs/docs/track-progress/`
   - **File Naming**: `YYYY-MM-DD.md` (e.g., `2026-09-30.md`)
   - **Trigger (Kapan Ditulis)**: BUKAN setiap `git push`. Tulis/update HANYA saat salah satu kejadian berikut:
     - (a) Checklist di `exec/` dicentang/direvisi (phase selesai, task baru ditambah)
     - (b) Prioritas di `MOSCOW_FEATURES.md` berubah (Must/Should/Could/Won't dipindah)
     - (c) Spec inti berubah (`PRD.md`, `technical.md`, `DATABASE.md`, `DESIGN.md`, `plans/`)
     - (d) Pencapaian milestone (mis. R2 selesai, backend deploy, QA lolos)
     - Jika dalam 1 hari ada banyak perubahan, cukup 1 file hari itu yang di-append (bukan 1 file per commit).
   - **Format**: Must include: Ringkasan Hari Ini, Evaluasi per MoSCoW, Keputusan Rilis/Web-vs-Mobile, Perubahan Fitur, Next Step (checklist).
   - **Automation Contract**: Any agent that does (a)–(d) MUST also update today's `track-progress/YYYY-MM-DD.md`. If the file for today does not exist, create it from the template in `track-progress/2026-09-30.md`.
   - **Retention**: Logs are append-only per day; never delete past logs. Use new date file for new day.
   - **Opsional (Git Hook)**: Jika ingin otomatisasi, pasang `post-commit` hook yang mengingatkan (bukan memaksa) untuk cek `exec/` — jangan auto-generate log dari `git log` karena commit ≠ progress fitur.
