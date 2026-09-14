# ALUR — PRD (Final)

**Status**: Dokumen otoritas eksekusi. Menggantikan seluruh dokumen sebelumnya (PRD v1, Blueprint v2, List Page, PRD v2 Simplified).

---

## 1. Visi

Frontend sesederhana kertas coretan. Backend secanggih tim asisten pribadi otonom.

User buka app, lihat hari ini, centang, atau lempar ide mentah lewat satu tombol brain-dump. Harada Method, 8 Pilar, chat sebagai interface utama, multi-tab, dan gamifikasi — semua dibuang; itu beban administrasi yang justru melawan tujuan produk ini. North Star Metric: **DCDC (Daily Conscious Decision Count)** — task yang dipilih sadar, bukan sekadar diselesaikan atau disembunyikan oleh AI.

---

## 2. UI/UX Spec

```
MONDAY                                    ← hari aktif, auto-expanded
April, 14 2025 — 9:41am
☑ 5km run                                 (strikethrough saat done)
☐ Read 10 pages
☐ Walk the dog (?)                        ← (?) = hasil brain-dump, durasi/waktu belum jelas
☐ Get groceries
💬 "Riset desain to-do app" kemarin gak dicentang — lupa atau emang skip?
   [Udah, lupa centang]  [Emang skip]  [Pindah ke hari ini]

[+ Add a new task...]        [🎙 Brain-dump]

TUESDAY   ── collapsed strip
WEDNESDAY ── collapsed strip
```

- Task `(?)` → tap sekali → 1 baris input inline ("Kapan? Berapa lama?"). Bukan modal, bukan chat.
- Task miss → tetap di tempatnya, visual redup. Kalau Scheduler Agent punya saran pindah, muncul 1 baris kecil: *"AI sarankan pindah ke Rabu · [Terima] [Abaikan]"* — user yang putuskan, AI tidak pernah pindahkan sendiri.
- Follow-up chip (lihat contoh di atas) hanya muncul untuk task yang terhubung goal atau task berulang — bukan untuk setiap task miss, biar tidak jadi notifikasi nyinyir harian.
- Tidak ada dashboard, grafik, atau halaman kedua. Dark/light mode sejak hari pertama.

---

## 3. Data Model

```sql
users
  id, email, name, timezone, daily_capacity_hours, preferences (json)

goals
  id, user_id, title, status (ACTIVE | DONE | ARCHIVED)

tasks
  id, user_id, goal_id (nullable)
  title
  assigned_date
  estimated_minutes (nullable — null → tampil sebagai "(?)")
  recurrence_rule (nullable text, contoh: "2x/minggu")
  status (PENDING | DONE | MISSED)
  is_ambiguous (boolean)
  ai_generated (boolean)
  source (MANUAL | BRAIN_DUMP)
  missed_follow_up (NONE | PENDING | FORGOT | SKIPPED | RESCHEDULED, default NONE)

ai_insights
  id, user_id, content, week_of, surfaced (boolean)
```

Habit berulang tidak punya tabel sendiri — cukup `tasks` dengan `recurrence_rule` terisi. Satu model data untuk dua kebutuhan.

---

## 4. Arsitektur Backend — Multi-Agent + LangGraph + Cron

**Stack**: LangGraph (orchestration) + LangChain (agent runtime) + Gemini/Groq (LLM) + Supabase (`pg_cron` + PostgreSQL).

```
                    ┌───────────────────────────┐
   [User Action] →  │       ORCHESTRATOR         │  ← LangGraph state machine
                    │  gatekeeper: kapan insight/ │
                    │  follow-up boleh tampil     │
                    └────┬───────────┬───────────┘
                         │           │
              (real-time)│           │(triggered by cron)
                         ▼           ▼
              ┌──────────────┐  ┌─────────────────────────┐
              │ EXTRACTOR    │  │  REFLECTION AGENT         │
              │ AGENT        │  │  (nightly + weekly)       │
              │              │  │                            │
              │ Brain-dump → │  │ - Tandai task MISSED       │
              │ list task    │  │ - Pilih mana yang perlu    │
              │ terstruktur, │  │   follow-up (goal-linked   │
              │ flag         │  │   atau recurring)          │
              │ is_ambiguous │  │ - Cari pola lintas minggu   │
              └──────┬───────┘  │ - Tulis ke ai_insights      │
                     │          └───────────┬────────────────┘
                     ▼                      │
              ┌──────────────┐              │
              │ SCHEDULER    │◄─────────────┘ (baca insight untuk
              │ AGENT        │                  reasoning jadwal
              │              │                  minggu depan)
              │ Taruh task,  │
              │ cek capacity │
              │ harian       │
              │ (invisible), │
              │ saran        │
              │ reschedule   │
              └──────────────┘
```

**Cron jobs (jalan tanpa trigger user):**

| Job | Frekuensi | Tugas |
|---|---|---|
| `nightly-status-check` | 00:00 per timezone user | Tandai task lewat hari → `MISSED`. Reflection Agent (versi ringan) pilih mana yang perlu `missed_follow_up = PENDING`. |
| `weekly-reflection` | Minggu malam | Analisis pola seminggu, tulis 1 insight ke `ai_insights` kalau ada goal dengan ≥2 task MISSED. |
| `weekly-recurrence-generator` | Minggu malam | Generate baris task baru dari semua `recurrence_rule` aktif untuk minggu depan. |

Default orchestrator: diam. Cuma bicara untuk 3 hal — task ambigu, saran reschedule, dan follow-up task miss yang lolos seleksi Reflection Agent.

---

## 5. Core Flows

**Brain-Dump → Task**
```
User kirim raw text/suara → Extractor Agent pecah jadi N task draft
  → durasi/waktu tidak jelas → is_ambiguous = true
  → Scheduler Agent taruh ke assigned_date sesuai capacity harian tersisa
  → UI refresh, task ambigu tampil dengan (?)
```

**Eksekusi Harian** (tidak menyentuh AI sama sekali)
```
User buka app → hari ini auto-expanded → centang task → status = DONE
```

**Malam Hari (Cron, Invisible)**
```
00:00 → task belum dicentang → MISSED
       → Reflection Agent (ringan) cek: goal-linked atau recurring?
         → ya: missed_follow_up = PENDING (muncul chip besok pagi)
         → tidak: diam, cuma tercatat sebagai histori
Minggu malam → weekly-reflection + weekly-recurrence-generator jalan
```

**Follow-up Miss (Baru)**
```
User buka app besok pagi → task dengan missed_follow_up = PENDING tampil chip:
  [Udah, lupa centang] → status = DONE, missed_follow_up = FORGOT
  [Emang skip]         → status tetap MISSED, missed_follow_up = SKIPPED
  [Pindah ke hari ini] → assigned_date = today, status = PENDING, missed_follow_up = RESCHEDULED
```
Jawaban ini masuk sebagai sinyal ke Reflection Agent selanjutnya — membedakan "lupa" vs "sengaja skip" jauh lebih berguna untuk insight mingguan daripada asumsi AI sendiri.

---

## 6. Fase Eksekusi

| Fase | Fokus | Yang Dibangun |
|---|---|---|
| **Fase 1 — UI Core** | Validasi desain | Accordion Mon–Sun, tambah task manual, centang, dark/light, animasi buka-tutup. Tanpa AI. |
| **Fase 2 — Brain-Dump + LangGraph** | AI masuk, sekaligus jadi latihan orchestration | Extractor Agent, Scheduler Agent, dan follow-up flow — semuanya diorkestrasi lewat LangGraph sejak awal (bukan 2 LLM call linear). Ini lebih berat dari yang sebenarnya diperlukan secara teknis di fase ini, tapi kalau tujuannya juga belajar LangGraph, ini titik yang tepat untuk mulai — state antar-node (extract → validate ambiguity → schedule) sudah cukup nyata untuk dipelajari tanpa harus menunggu Fase 3. |
| **Fase 3 — Otonomi Penuh** | Multi-agent + cron lengkap | Reflection Agent, seluruh cron job, saran reschedule, voice-to-text. |

---

## 7. Non-Goals

Harada Method / 8 Pilar / 64-Grid, chat room sebagai interface utama, multi-tab navigation, web dashboard, gamifikasi (streak/leaderboard/level), auto-reschedule tanpa persetujuan user.

---

## 8. Dokumen Lama

`PRODUCT REQUIREMENTS DOCUMENT (PRD)` v1, `Blueprint v2`, `List Page atau Halaman`, `PRD v2 Simplified` — diarsipkan sebagai referensi histori, tidak dirujuk lagi.
