# Implementation Plan: Web-First Target Harian + Goal Breakdown

> Tanggal: 2026-10-03 | Status: Fase 1 SELESAI — Auth Google web + Target Harian API live, lanjut Fase 2 R2b
> Basis: `ALUR_rekap_penyesuaian_dokumen.md` + verifikasi repo + Supabase live `alurproject-dev`
> Keputusan kunci: Vercel Tahap 1 sampai VPS | Istilah Target Harian | Goal Planner UX chat, pipeline terpisah

## Goal Description

### Problem Statement
P1 pagi bingung prioritas, P2 target jarang tuntas, P3 tidak paham pola. Web masih mock `localStorage` (`web/app/page.tsx`) dan belum tersambung API. Backend belum punya endpoint Goals sehingga hari pertama kosong dan M5 tidak punya bahan.

### What This Plan Accomplishes
Web tersambung backend dan siap dipakai. Target Harian terisi dari Goal manual lalu AI. Morning Brief + Capacity Warning jalan. Reschedule + insight menyusul setelah aktivasi terbukti.

## Resolved Decisions
1. Deploy tetap Vercel Tahap 1 untuk backend + web sampai pindah VPS. `feedback.md B2` (Render) dinyatakan superseded.
2. Istilah: nav `Target`, layar `Target Harian`, satuan `tugas`, gagal disebut `Terlewat`.
3. Semua MISSED dapat chip. Goal-linked dapat saran tanggal, tugas lepas hanya catat alasan.
4. Goal Planner UX seperti brain-dump/chat, backend service terpisah dari graph chat.
5. Semua generate AI async `202 GENERATING → DRAFT → ACCEPTED`.

## Proposed Changes

### Fase 0 — Fondasi DB + Dokumen (P0)
- [x] Tandai `feedback B2` superseded oleh `DEPLOYMENT_GUIDE`. Samakan `technical §7`/`§9` ke Vercel + `config.py`.
- [x] Migrasi `017_add_goal_planning.sql` applied ke live: enum `GOAL_PLAN`, 6 kolom `goals`, `tasks.user_modified` terverifikasi via MCP.
- [x] Tetapkan key `preferences`: `fixed_blocks`, `onboarding_completed_at` (+ endpoint `PATCH /users/me/preferences`). `todo_default_view` tetap.
- [ ] Cek gap migrasi 008-011 via `supabase db diff --linked` (butuh CLI, tidak blocker).

### Fase 1 — Backend Minimal + Web Tersambung (P0 Blocker)
- [x] Backend `goals.py`: `POST/GET/PATCH/DELETE /goals`, `POST /goals/{id}/plan` 202 async, `GET plan`, `POST plan/accept` (+ `GoalService` materialisasi manual 7 hari).
- [x] Backend `PATCH /users/me/preferences`: kapasitas, jam tetap, timezone, onboarding (+ `users.py`, `UserService`).
- [x] Kontrak plan manual: AI usul → user terima 1x → tulis `tasks` GOAL_PLAN. Breakdown AI penuh masuk Fase 2.
- [x] Web: ganti `localStorage` ke API JWT (`lib/api.ts` ditulis ulang, tanpa `X-User-Id` dummy, tipe selaras backend).
- [x] Web: Target hybrid Weekly 7 kolom, quick-add 1 baris per kolom, edit minimal (judul + tanggal + estimasi + goal), clarify `(?)`, label `dari Goal:`, meta kapasitas + warning overload, empty state + Goal panel M14-manual.
- [x] Buang di web v1: BrainDumpModal, SomedayDrawer, DayColumn/WeekGrid/TaskRow/CalendarView/InsightBanner lama, rich-text, stabilo, subtask, lampiran, pengingat. `npm run build` sukses.
- [x] Auth Google web + proteksi route (Supabase OAuth via `signInWithOAuth`, callback `/auth/callback`, AuthGate di `page.tsx`, middleware refresh session, JWT `alur_jwt` sinkron otomatis, logout di header).
- [x] `next.config.mjs` baca `.env` root terpusat (ENV_GUIDE §3B Cara 1) + petakan `PUBLIC_*` ke `NEXT_PUBLIC_*`.

Done Fase 1: buka web pagi → login Google → Target terisi dari Goal manual, bisa CRUD, kapasitas terhitung jujur.

Done Fase 1: buka web pagi, Target terisi dari Goal manual, bisa CRUD, kapasitas terhitung jujur.

### Fase 2 — R2b Aktivasi AI (P1)
- [ ] Breakdown AI async + rolling replan Minggu malam gabung job mingguan.
- [ ] M5 Morning Brief Top 3 via cron (total ≤ kapasitas), M6 Capacity Warning tanpa auto-pindah, M11 default diam.
- [ ] Goal chat-UX: ketik bebas goal → draft milestone + 7 hari → Terima / Edit / Milestone saja + saran strategis jika tidak muat.

Done Fase 2: hari pertama tidak kosong, ada Top 3 + warning.

### Fase 3 — Reschedule + Insight (P2)
- [ ] M7 nightly PENDING→MISSED, M8 saran 1-tap, M9 chip semua tugas.
- [ ] M10 insight naratif mingguan tanpa grafik, S3 Calendar read-only sebagai visual kapasitas.

### Won't v1
Someday Drawer, auto tanpa setuju, gamifikasi, Harada, kolaborasi tim, Chat + Profile di web, `GOAL_CAPTURE` di chat.

## Metrik
M14: acceptance, edit rate, completion goal vs manual, goal aktif D28. DCDC: pilih Top 3 + terima/tolak saran + tandai alasan. Guardrail: opt-out, tap <1 detik, retensi D7/D30. Ambang setelah baseline 2 minggu.
