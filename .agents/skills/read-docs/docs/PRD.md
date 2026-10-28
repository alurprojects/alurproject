# ALUR — Product Requirements Document

## 1. Visi & Positioning
- 1 kalimat positioning: "ALUR adalah productivity companion yang secara aktif jujur tentang kapasitas kamu — bukan yang kamu harap-harapkan."
- Frontend sesederhana kertas coretan. Backend secanggih tim asisten pribadi otonom.
- North Star Metric: DCDC (Daily Conscious Decision Count)
- Target user: General Productivity 18-35, siapa saja yang merasa overwhelmed

## 2. Core Concept — Realistic Planner + AI Companion
- ALUR bukan sekadar to-do list — itu AI yang belajar pola kamu lewat 2 saluran:
  - **To-do List** (eksekusi harian): centang, tambah task, lihat jadwal
  - **Chat Room** (refleksi & capture): curhat kendala, brain-dump ide, tanya AI soal kapasitas
- AI memilah otomatis: input di Chat Room → apakah task baru, refleksi, atau curhat biasa
- Semakin lama dipakai, semakin jujur dan relevan AI-nya (data dari to-do + chat terakumulasi)

## 3. UI/UX Spec

### 3.1 Navigasi Mobile (3 Tab Menu + Top-Right Profile)
Navigasi utama mobile apps disederhanakan menjadi **3 tab menu bawah** saja, sementara akses Profile dipindahkan ke **pojok kanan atas (Top-Right Action)**:

| Posisi | Navigasi | Fungsi Utama |
| :--- | :--- | :--- |
| Bottom Nav: Kiri | **Home** | Dashboard ringkasan harian, Morning Priority Brief (Top 3), status kapasitas harian & quick action |
| Bottom Nav: Tengah | **To Do List** | Hybrid Daily Focus & Weekly Overview, manajemen & eksekusi tugas, checklist, follow-up chips |
| Bottom Nav: Kanan | **Chat** | Brain-dump quick capture + Curhat kendala + AI companion & capacity check-in |
| Header Kanan Atas | **Profile** | Ikon/Avatar profil untuk akses Goals, Settings (kapasitas, timezone, notifikasi), Retensi Chat, & Logout |

> **Catatan Navigasi:**
> - **Calendar di-hold dulu:** Tab Calendar (time-block) ditunda sementara dari bottom bar mobile apps v1 agar antarmuka fokus pada eksekusi dan kejujuran kapasitas.
> - **Profile geser ke kanan atas:** Mengurangi kepadatan bottom navigation bar dan memisahkan fungsi operasional harian (Home, To Do List, Chat) dengan pengaturan akun.

### 3.2 Home Tab (Daily Overview & Morning Brief)
- Puncak layar: **Morning Priority Brief banner** (Maks. Top 3 prioritas hari ini + 1 kalimat alasan)
- **Status Kapasitas Harian:** Indikator total estimasi waktu vs `daily_capacity_hours`, visualisasi overload warning jika melebihi kapasitas
- **Quick Action:** Tombol cepat untuk tambah tugas baru atau mulai brain-dump ke Chat

### 3.3 To Do List Tab (Hybrid View)
- **Default: Daily Focus** — hanya tampilkan HARI INI
  - Swipe kiri/kanan untuk hari lain
  - Task di-render sebagai list dengan checkbox
  - Follow-up chip untuk task miss (goal-linked/recurring only)
  - "+ Add task" inline input
  - Tombol akses cepat ke Chat untuk brain-dump
- **Toggle: Weekly Overview** — accordion Mon-Sun seperti design existing
  - Expand/collapse per hari
  - Overview semua task minggu ini

### 3.4 Chat Tab (Brain-dump & AI Companion)
- Tampilan chat sederhana — minimalis sesuai design language ALUR
- Fungsi utama: **Capacity check-in & task capture**, bukan ruang obrolan bebas
- User bisa:
  - Ketik 1 baris cepat → AI parsing sebagai task (brain-dump quick capture)
  - Tanya soal kapasitas → "Aku masih bisa ngerjain apa hari ini?"
  - Ceritakan kendala → AI mendengarkan, lalu mengarahkan balik ke pertanyaan kapasitas ("Kedengarannya berat, mau kita lihat beban minggu ini?")
- AI otomatis memilah:
  - Teks yang mengandung task → extract ke tasks table, konfirmasi ke user
  - Teks yang berisi kendala/refleksi → simpan ke conversation_logs, jadi bahan Reflection Agent
- History chat tersimpan dan scrollable
- AI personality: 2-tone system (HONEST default, GENTLE saat mendeteksi sinyal overload/burnout)

### 3.5 Calendar (ON-HOLD untuk Mobile v1)
- *Status: Ditunda / On-Hold pada Mobile Apps v1.*
- Konsep: Time-block view vertikal (06:00-22:00) yang merepresentasikan data to-do dalam format waktu (read-only status).
- Dialihkan ke status On-Hold pada tab bar mobile v1 agar user fokus pada Home dan To Do List. Integrasi Google Calendar (Tahap B, read-only) tetap dipertahankan dalam roadmap mendatang.

### 3.6 Profile (Top-Right Action)
- Diakses via ikon/avatar di pojok kanan atas layar (Top Bar), bukan bottom tab menu.
- Info akun user
- Goals section (list ACTIVE goals, tap expand ke sub-tasks)
- Settings: theme, timezone, notifications, daily_capacity_hours
- Notice banner retensi chat (muncul HANYA kalau ada log berstatus pending-deletion):
  - Teks: "X riwayat chat lebih dari 83 hari akan dihapus permanen dalam 7 hari."
  - [Unduh Backup] → trigger `POST /chat/history/export`, simpan sebagai file lokal di device
  - [Simpan Selamanya] → `PATCH /chat/history/retention-override` untuk log tersebut
  - [Oke, hapus saja] → tidak melakukan apa-apa, biarkan cron jalan normal
- Tombol "Hapus Riwayat Chat" — hapus seluruh `conversation_logs` milik user via `DELETE /chat/history`, dengan konfirmasi 2-langkah (karena destruktif dan tidak bisa di-undo)
- Logout

### 3.7 Web App — Scope Terbatas
Web app v1 HANYA berisi:
- To-do (Hybrid Daily/Weekly, sama seperti mobile Section 3.2)
- Calendar (read-only, sama seperti mobile Section 3.4)

TIDAK ada Chat Room atau Profile di web v1. User yang mau brain-dump/chat tetap harus buka mobile. Ini keputusan sadar untuk membatasi permukaan kerja, bukan keterbatasan teknis.

## 4. Data Model

```sql
users     (id, email, name, timezone, daily_capacity_hours, preferences json)
goals     (id, user_id, title, description, deadline, priority, status: ACTIVE|DONE|ARCHIVED)
tasks     (id, user_id, goal_id?, title, assigned_date,
           estimated_minutes?, recurrence_rule?,
           recurrence_group_id?,
           status: PENDING|DONE|MISSED,
           is_ambiguous, ai_generated, source: MANUAL|BRAIN_DUMP|CHAT_ROOM,
           missed_follow_up: NONE|PENDING|FORGOT|SKIPPED|RESCHEDULED)
conversation_logs  (id, user_id, role: USER|AI, content, message_type: TASK_CAPTURE|REFLECTION|CHAT|CAPACITY_QUERY, extracted_task_ids[], session_date, created_at)
ai_insights (id, user_id, content, insight_type: WEEKLY_REFLECTION|CAPACITY_WARNING|PATTERN_DETECTION, week_of, surfaced, source_data json)
task_suggestions (id, task_id, user_id, suggested_date, reason, status: PENDING|ACCEPTED|REJECTED, responded_at)
google_calendar_connections (Tahap B)
```

> [!NOTE]
> - `task_source` enum now includes `CHAT_ROOM` for tasks extracted from chat.
> - `conversation_logs` is the NEW table that stores all chat interactions.
> - `ai_insights.insight_type` distinguishes different kinds of AI observations.

## 5. Backend Architecture — Multi-Agent + LangGraph

Stack: LangGraph (orchestration) + LangChain (agent runtime) + Gemini/Groq (LLM) + Supabase (pg_cron + PostgreSQL)

### Agent Architecture

| Agent | Trigger | Tugas |
| :--- | :--- | :--- |
| Extractor Agent | Real-time (Chat Room input) | Parse teks bebas → task terstruktur OR refleksi OR curhat. Flag is_ambiguous. |
| Scheduler Agent | Setelah Extractor / cron | Set assigned_date, cek capacity, saran reschedule |
| Reflection Agent | Cron nightly + weekly + Chat Room data | Tandai MISSED, pilih follow-up, cari pola dari combined data (tasks + chat logs), tulis ai_insights |
| Companion Agent | Real-time (Chat Room) | Merespons curhat/pertanyaan user dengan personality adaptive. Bisa warm, tegas, atau minimal tergantung konteks. |
| Orchestrator | Selalu aktif | Gatekeeper: kapan insight/follow-up/saran boleh tampil. Default diam. |

### Companion Agent Detail (BARU)
- Input: conversation_logs dari Chat Room
- Akses: tasks (current week), ai_insights (recent), conversation_logs (last 7 days)
- Output: respons teks ke user + optional task extraction + overload signal tagging
- Personality system: 2-tone system:
  - HONEST (default): nada lugas, menyajikan data/konsekuensi apa adanya
  - GENTLE (kondisional): dipakai HANYA saat mendeteksi tanda burnout/overload nyata — tetap jujur, cuma lebih pelan cara menyampaikannya
- Faktor pengaruh tone: completion_rate 7 hari terakhir, consecutive misses

### Cron Jobs
| Job | Frekuensi | Tugas |
| :--- | :--- | :--- |
| nightly-status-check | 00:00 per timezone user | Tandai MISSED, Reflection ringan → follow-up |
| weekly-reflection | Minggu malam | Analisis pola COMBINED (tasks + chat logs) → ai_insights |
| weekly-recurrence-generator | Minggu malam | Generate task recurring untuk minggu depan |

## 6. Core Flows

### Brain-dump via Chat Room
User ketik di Chat Room → Companion Agent + Extractor Agent → AI parsing → task/refleksi/curhat dipilah → jika task: insert ke DB, konfirmasi ke user → UI refresh

### Eksekusi Harian
User buka app → Home (cek Morning Brief & Kapasitas) / To Do List tab → Daily Focus (hari ini) → centang task → status = DONE

### Curhat/Refleksi
User ketik di Chat Room tentang kendala → AI merespons dengan empati → conversation disimpan → data ini jadi input Reflection Agent untuk insight mingguan

### Capacity Check (via Chat Room)
User tanya "Masih bisa ngerjain apa hari ini?" → Companion Agent cek remaining capacity → respons dengan rekomendasi realistis

### Nightly Cron
00:00 → PENDING task → MISSED → Reflection Agent cek combined data → follow-up/insight

## 7. Fase Eksekusi

| Fase | Fokus | Yang Dibangun |
| :--- | :--- | :--- |
| 1 — UI Core | Validasi desain | Hybrid Daily/Weekly to-do di To Do List tab, Home tab (Morning Brief slot & kapasitas), Chat tab UI shell, Top-Right Profile, 3-tab bottom nav, auth Google OAuth, dark/light. Calendar di-hold. Tanpa AI. |
| 2 — Chat Room + LangGraph | AI masuk | Extractor Agent, Companion Agent, Scheduler Agent, conversation_logs, diorkestrasi via LangGraph. Chat Room jadi functional. |
| 3 — Otonomi Penuh | Multi-agent + cron | Reflection Agent dengan combined data, seluruh cron, saran reschedule, voice-to-text, adaptive personality tuning. |

## 8. Non-Goals

Harada/8-Pilar, gamifikasi (streak/leaderboard/level), auto-reschedule tanpa persetujuan user, learning_style/personalisasi cara-belajar. Calendar tab BUKAN pengganti to-do dan di-hold sementara untuk rilis mobile apps v1. Web app scope awal dibatasi ke To-do + Calendar (read-only); Chat Room & Profile di web ditunda sampai versi mobile stabil.

## 9. Key Differentiators

1. **Honest capacity** — AI yang secara aktif meragukan komitmen tidak realistis, bukan yang selalu bilang "kamu pasti bisa"
2. **FORGOT vs SKIPPED** — AI membedakan lupa vs sengaja skip sebagai bahan kejujuran, bukan asumsi 'gagal'
3. **Invisible complexity** — UI tetap sesederhana kertas, kejujuran itu ada di balik layar, bukan diumbar sebagai dashboard/grafik
