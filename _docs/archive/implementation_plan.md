# ALUR — Implementation Plan

Stack: Flutter (mobile) · FastAPI (backend) · Supabase/Postgres · LangChain + LangGraph · Gemini/Groq · `pg_cron`.

---

## Fase 1 — UI Core (tanpa AI)

**Tujuan**: accordion mingguan hidup, task manual bisa ditambah & dicentang.

**DB**
- [x] Migrasi `users`, `goals`, `tasks` (kolom AI: `is_ambiguous`, `ai_generated`, `missed_follow_up` tetap dibuat sekarang, diisi default supaya tidak ada migrasi ulang di Fase 2)
- [x] RLS policy per `user_id`

**Backend**
- [x] `POST /tasks` (manual create)
- [x] `PATCH /tasks/{id}` (toggle status)
- [x] `GET /tasks?week=` (fetch 7 hari)

**Frontend (Flutter)**
- [x] Widget accordion per hari (expand/collapse animasi)
- [x] Auto-expand hari ini berdasarkan `timezone` user
- [x] Checkbox + strikethrough state
- [x] Input `+ Add a new task...` → panggil `POST /tasks`
- [x] Dark/light theme (bukan setting tersembunyi — toggle terlihat)

**Exit criteria**: user bisa buka app, isi minggu manual, centang, ganti tema. Tidak ada dependency ke LLM sama sekali di fase ini.

---

## Fase 2 — Brain-Dump + LangGraph

**Tujuan**: input bebas → task terjadwal otomatis, sekaligus setup orchestration untuk dipakai lagi di Fase 3.

**LangGraph setup**
- [x] Node `extractor`: prompt LLM → output JSON `[{title, estimated_minutes|null, goal_id|null}]`
- [x] Node `validate_ambiguity`: rule check — kalau `estimated_minutes` null → set `is_ambiguous=true`
- [x] Node `scheduler`: baca `daily_capacity_hours` + task existing per hari dari DB → assign `assigned_date`
- [x] Edge: `extractor → validate_ambiguity → scheduler`
- [x] Compile graph, expose sebagai satu fungsi `run_brain_dump(text, user_id)`

**Backend**
- [x] `POST /brain-dump` → invoke graph → insert hasil ke `tasks` (`source=BRAIN_DUMP`)
- [x] `PATCH /tasks/{id}/clarify` → isi `estimated_minutes` manual dari tap `(?)`

**Frontend**
- [x] Tombol 🎙/teks brain-dump (bisa mulai dari teks saja, voice nanti di Fase 3)
- [x] Render tanda `(?)` untuk `is_ambiguous=true`
- [x] Tap `(?)` → input inline durasi/waktu → `PATCH /clarify`

**Exit criteria**: brain-dump teks bebas menghasilkan task di hari yang tepat, task ambigu bisa diklarifikasi tanpa modal/chat.

---

## Fase 3 — Otonomi Penuh

**Tujuan**: sistem berjalan sendiri tanpa trigger user.

**Cron (Supabase `pg_cron` atau scheduled Edge Function)**
- [x] `nightly-status-check` (00:00/timezone): `PENDING` + lewat hari → `MISSED`
- [x] Extend LangGraph dengan node `reflection_light`: dari task `MISSED`, cek `goal_id IS NOT NULL OR recurrence_rule IS NOT NULL` → set `missed_follow_up=PENDING`
- [x] `weekly-reflection` (Minggu malam): node `reflection_full` — agregasi per goal, kalau ≥2 `MISSED` di goal yang sama → tulis `ai_insights` (`surfaced=true`)
- [x] `weekly-recurrence-generator`: baca semua `recurrence_rule` aktif → generate task minggu depan

**Backend**
- [x] `PATCH /tasks/{id}/follow-up` → handle 3 opsi (Lupa/Skip/Pindah) → update `status` + `missed_follow_up`
- [x] `GET /insights?surfaced=true` → untuk ditampilkan di UI

**Scheduler Agent — reschedule suggestion**
- [x] Tambah node `overload_check` di graph: kalau total `estimated_minutes` di 1 hari > `daily_capacity_hours` → generate saran pindah hari lain
- [x] `PATCH /tasks/{id}/reschedule` (accept/reject saran)

**Frontend**
- [x] Render chip follow-up (3 tombol) di task yang `missed_follow_up=PENDING`
- [x] Render baris saran reschedule + tombol Terima/Abaikan
- [x] Voice input → speech-to-text (Whisper/Gemini audio) → kirim ke `/brain-dump` sebagai teks

**Exit criteria**: tanpa user membuka app sama sekali, minggu depan sudah terisi dari recurrence; user cuma perlu menjawab chip yang muncul kalau relevan.

---

## Urutan Kerja yang Disarankan

1. Jangan mulai coding LangGraph sebelum Fase 1 selesai dan bisa dipakai harian oleh diri sendiri minimal 1 minggu.
2. Fase 2: bangun `extractor` node dulu, tes manual lewat script/notebook sebelum disambung ke `scheduler` node — supaya bug parsing tidak tercampur bug penjadwalan.
3. Fase 3: cron jobs ditulis & ditest lokal dulu (jalankan manual via endpoint debug) sebelum didaftarkan ke `pg_cron` — supaya tidak debug production job yang jalan sendiri tengah malam.
