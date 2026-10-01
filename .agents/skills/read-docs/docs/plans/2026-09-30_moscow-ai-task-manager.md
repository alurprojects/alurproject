# MoSCoW — AI Task Management & Productivity Companion (ALUR)

> **Tanggal:** 2026-09-30
> **Status:** Draft v1 — Product Design
> **Sumber Kebenaran:** `PRD.md`, `technical.md`, `DATABASE.md`, `DESIGN.md`
> **Masalah Inti:**
> 1. Kebingungan menentukan prioritas kerja setiap pagi (*morning decision paralysis*)
> 2. To-do list harian jarang tuntas 100% → tugas tertunda menumpuk tanpa penanganan sistematis
> **Solusi Inti:** AI yang memberikan **analisis produktivitas mendalam** + **otomatis menjadwalkan ulang / mendelegasikan** tugas tertunda ke hari lain (dengan persetujuan user)

---

## 1. Prinsip Prioritisasi ALUR

Sesuai `PRD.md` §1 & §9, ALUR bukan to-do list biasa. Positioning: *"productivity companion yang secara aktif jujur tentang kapasitas kamu"*.

Maka MoSCoW disaring dengan 3 filter invariant:

| Filter | Pertanyaan |
| :--- | :--- |
| **Honest Capacity** | Apakah fitur ini membuat user jujur soal kapasitas, bukan sekadar `kamu pasti bisa`? |
| **Invisible Complexity** | Apakah kompleksitas tetap di backend (LangGraph), frontend tetap sesederhana kertas? |
| **FORGOT vs SKIPPED** | Apakah fitur membedakan *lupa* vs *sengaja skip* sebagai bahan refleksi, bukan label gagal? |

Fitur yang lolos ketiga filter → **Must Have**.

---

## 2. Matriks MoSCoW

### 2.1 MUST HAVE — Wajib Ada di MVP (Tanpa ini, masalah tidak selesai)

> Jika tidak dibangun, user **tetap bingung tiap pagi** dan **tugas tertunda tetap menumpuk**.

| # | Fitur | Deskripsi Spesifik | Masalah yang Diselesaikan | Mapping Teknis ALUR |
| :--- | :--- | :--- | :--- | :--- |
| M1 | **Hybrid To-do: Daily Focus + Weekly Overview** | Default Daily Focus (HARI INI saja), swipe kiri/kanan ganti hari. Toggle ke Weekly accordion Mon-Sun. `+ Add task` inline, checkbox bulat. | Mengurangi overload visual — user fokus pada *hari ini* saja, bukan 30 task seminggu sekaligus. | `PRD §3.2`, `tasks.assigned_date`, `mobile/screens/todo` + `web/app/page.tsx` |
| M2 | **Morning Brief — Prioritas Otomatis Tiap Pagi** | Setiap jam `reminder_hour` (default 07:00 lokal), sistem generate brief: 3-5 task prioritas hari ini (Top Priority), sisa kapasitas jam, warning jika overload. Disajikan sebagai banner di To-do tab + push notification. | **Jawaban langsung** untuk "mau ngerjain apa dulu pagi ini?" — user tidak perlu mikir, AI sudah memilah. | `MorningBriefService` (`technical §6`), `morning_briefs` table, cron `morning-brief-generator` (`DATABASE §12`) |
| M3 | **AI Auto-Reschedule — Tugas Tertunda Dijadwalkan Ulang** | `nightly-status-check` 00:00/timezone: `PENDING → MISSED`. Lalu `Scheduler Agent` buat `task_suggestions` (suggested_date + reason: *overload / capacity*) untuk task `goal-linked` atau `recurring`. User pilih: `[Pindah hari ini] → RESCHEDULED`, `[Emang skip] → SKIPPED`, `[Udah, lupa centang] → FORGOT`. | To-do tidak pernah 100% itu **normal**. Sistem mengakui & menawarkan jalur keluar, bukan membiarkan task hilang. | `Scheduler Agent`, `task_suggestions` (`DATABASE §7`), state machine `missed_follow_up` (`DATABASE §10`) |
| M4 | **Honest Capacity Warning** | Saat `estimated_minutes` total hari > `daily_capacity_hours`, AI tampilkan warning jujur: *"Beban hari ini 9.5 jam, kapasitasmu 6 jam — mau pindah 2 task ke besok?"* Tidak auto-pindah tanpa izin. | Mencegah user over-commit pagi hari — akar penyebab to-do tidak tuntas. | `Scheduler Agent` + `ai_insights.insight_type = CAPACITY_WARNING`, `users.daily_capacity_hours` |
| M5 | **Chat Room — Brain Dump & Capacity Check-in** | Input bebas di Chat Room: ketik 1 baris → `Extractor Agent` parse jadi task terstruktur (title, estimated_minutes, ambiguous flag). Tanya *"Aku masih bisa ngerjain apa hari ini?"* → `Companion Agent` jawab realistis. | Capture ide cepat tanpa friction + tempat curhat kendala yang jadi bahan analisis. | `Companion → Extractor → Scheduler` (`technical §5`), `conversation_logs`, `POST /chat/message` |
| M6 | **Auth Google OAuth + 4-Tab Navigation** | Login tanpa password. Navigasi tetap 4 tab: To-do | Chat Room | Calendar (read-only) | Profile. | Fondasi akses & struktur yang konsisten di Mobile & Web. | `PRD §3.1`, `technical §1` |

> **Definisi Done untuk Must Have:** User bisa bangun pagi, buka ALUR, langsung lihat 3 prioritas + warning kapasitas, eksekusi task, dan tugas yang miss keesokan paginya muncul sebagai chip follow-up yang bisa di-reschedule 1 tap.

---

### 2.2 SHOULD HAVE — Penting, Tapi Tidak Menghentikan Launch Jika Tertunda

> Tanpa ini MVP tetap jalan, tapi pengalaman terasa **kurang cerdas**.

| # | Fitur | Deskripsi | Nilai Tambah | Ketergantungan | Fase |
| :--- | :--- | :--- | :--- | :--- | :--- |
| S1 | **Analisis Produktivitas Mingguan (Weekly Reflection)** | Minggu malam `weekly-reflection` cron analisis **combined data** (`tasks` + `conversation_logs` 7 hari) → tulis `ai_insights` bertipe `WEEKLY_REFLECTION` & `PATTERN_DETECTION`. Contoh: *"Kamu 3x skip task Jumat sore — pola kelelahan akhir pekan?"* | Memberikan **analisis mendalam** yang dijanjikan di brief — bukan sekadar reschedule, tapi *mengapa* tidak tuntas. | Butuh M3 + M5 (data chat terkumpul) | Fase 3 |
| S2 | **Calendar Time-Block View (Read-Only)** | Visualisasi tasks dalam blok waktu vertikal 06:00-22:00. Unscheduled section di atas. Tap → navigasi ke To-do. | User melihat *kapan* task dijadwalkan, bukan hanya *apa* tasknya. Membantu reason kapasitas. | M1 | Fase 1 |
| S3 | **Google Calendar Read-Only Sync** | `calendar.readonly` OAuth — tarik events untuk kalkulasi waktu kosong (capacity calculation lebih akurat). | Kapasitas tidak lagi asumsi 8 jam, tapi dikurangi meeting yang sudah ada. | S2 | Tahap B |
| S4 | **RAG Semantic Retrieval (pgvector)** | `embeddings` vector(768) + `match_embeddings` RPC. Companion Agent bisa jawab *"Minggu lalu kamu juga bilang burnout hari Senin"* dengan grounding data historis, tanpa halusinasi. | Chat terasa *mengingat* user, bukan chatbot generik. | M5 | Fase 3 |
| S5 | **Adaptive Personality (HONEST ↔ GENTLE)** | 2-tone system: default HONEST (lugas, data-driven), switch ke GENTLE hanya saat deteksi sinyal overload/burnout (completion_rate 7 hari, consecutive misses, mood_detected). | AI tidak toxic positivity, juga tidak menghakimi saat user benar-benar down. | M5 | Fase 2-3 |
| S6 | **Follow-up Chip FORGOT vs SKIPPED Analytics** | Dashboard mini di Profile: rasio FORGOT/SKIPPED/RESCHEDULED mingguan. Bukan leaderboard. | User refleksi jujur: *sering lupa centang* vs *sering sengaja skip* → intervensi berbeda. | M3 | Fase 3 |

---

### 2.3 COULD HAVE — Nice to Have, Tingkatkan Delight

> Dikerjakan jika waktu/sumber daya berlebih. Tidak memengaruhi janji inti produk.

| # | Fitur | Deskripsi | Catatan |
| :--- | :--- | :--- | :--- |
| C1 | **Voice-to-Text Brain Dump** | Tekan mic di Chat Room → Whisper/Gemini Audio → teks → pipeline Extractor. | `technical §1` Fase 3. Berguna untuk capture sambil jalan. |
| C2 | **Clarify Prompt untuk Task Ambigu** | Task tanpa `estimated_minutes` (`is_ambiguous = TRUE`) tampil `(?)` → tap → inline input *"Berapa lama kira-kira?"* → `PATCH /tasks/{id}/clarify`. | Meningkatkan akurasi capacity warning. |
| C3 | **Recurring Task Generator** | `weekly-recurrence-generator` Minggu malam: auto-generate instance baru per `recurrence_group_id` (daily/weekdays/2x-week dll). | `DATABASE §9-10`. Mengurangi input manual habit. |
| C4 | **Chat History Export & Retention Control** | Profile banner: *"X riwayat chat >83 hari akan dihapus dalam 7 hari"* → [Unduh Backup] (`POST /chat/history/export`) / [Simpan Selamanya] (`PATCH /retention-override`) / [Oke, hapus]. | `PRD §3.5`, `DATABASE §12` cron `conversation-log-*`. |
| C5 | **Hierarchical Memory (Core Profile Condenser)** | Cron harian ringkas chat jadi `users.ai_profile_summary` JSON (~50 token) yang selalu di-inject ke prompt Companion. | `technical §6` — hemat token, personalisasi tanpa kirim history raksasa. |
| C6 | **Web App — To-do + Calendar Only** | Web v1 hanya To-do Hybrid + Calendar read-only. Tanpa Chat Room/Profile (sengaja dibatasi). | `PRD §3.6` — bukan keterbatasan teknis, tapi keputusan scope. |

---

### 2.4 WON'T HAVE (This Time) — Sadar Tidak Dibangun

> Disebut eksplisit agar tidak terjadi *scope creep*. Sesuai `PRD §8 Non-Goals`.

| # | Fitur yang DITOLAK | Alasan Penolakan | Alternatif yang Disediakan |
| :--- | :--- | :--- | :--- |
| W1 | **Auto-reschedule TANPA persetujuan user** | Melanggar *human-in-the-loop*. ALUR jujur, bukan mengambil alih keputusan. User harus tap `[Pindah hari ini]`. | `task_suggestions` dengan status `PENDING` → user Accept/Reject |
| W2 | **Gamifikasi: Streak, Leaderboard, Level, XP** | Menciptakan *toxic productivity* — bertolak belakang dengan *honest capacity*. | `ai_insights` reflektif + FORGOT/SKIPPED distinction |
| W3 | **Harada Method / 8 Pilar / Framework coaching berat** | Target user 18-35 general productivity, bukan atlet/coach. Terlalu kompleks untuk MVP. | Goals sederhana (`goals` table) + AI reflection ringan |
| W4 | **Calendar sebagai pengganti To-do (editable di Calendar)** | Calendar di ALUR adalah **representasi read-only** dari data To-do, bukan sumber kebenaran kedua. | Tap task di Calendar → navigasi ke To-do untuk edit |
| W5 | **Chat Room di Web v1** | Permukaan kerja dibatasi sadar. Brain-dump & curhat tetap di Mobile. | Mobile Chat Room penuh; Web fokus eksekusi |
| W6 | **Learning Style / Personalisasi cara-belajar** | Non-goal PRD. Bukan aplikasi edukasi. | `ai_profile_summary` hanya untuk gaya kerja & kapasitas |
| W7 | **Delegasi ke orang lain (human delegation)** | Kata "mendelegasikan" pada brief diinterpretasi sebagai *reschedule ke hari lain*, bukan assign ke user lain. Multi-user collaboration ditunda. | `suggested_date` reschedule + reason |

---

## 3. Prioritisasi Visual

```
Value Tinggi
    ▲
    │   M2 Morning Brief        S1 Weekly Reflection
    │   M3 Auto-Reschedule  ●   S4 RAG Retrieval
    │   M4 Capacity Warn    ●
    │   M5 Chat BrainDump   ●   S5 Adaptive Tone
    │   M1 Hybrid To-do     ●
    │                           C1 Voice Input
    │                           C2 Clarify Prompt
    │   W1-W7 (Won't Have)      C3 Recurring Gen
    └──────────────────────────────────────────►
         Effort Rendah              Effort Tinggi

● Must Have = Kuadran kiri-atas (value max, effort terukur)
```

---

## 4. Roadmap Eksekusi (Sinkron dengan PRD §7)

| Fase | Fokus | MoSCoW Coverage | Deliverable Kunci |
| :--- | :--- | :--- | :--- |
| **Fase 1 — UI Core** | Validasi desain tanpa AI | M1, M6, S2 (sebagian) | Hybrid Daily/Weekly, 4-tab nav, auth, dark/light. Chat Room sebagai shell kosong. |
| **Fase 2 — Chat Room + LangGraph** | AI masuk (real-time) | M2, M4, M5, S5 | Companion + Extractor + Scheduler via LangGraph, `conversation_logs`, Morning Brief v1 |
| **Fase 3 — Otonomi Penuh** | Multi-agent + cron + RAG | M3 (full), S1, S3, S4, S6, C1-C6 | Reflection Agent combined data, `task_suggestions` flow lengkap, `embeddings` pgvector, voice, recurrence |
| **Tahap B** | Calendar integration | S3 | Google Calendar OAuth read-only |

---

## 5. Kriteria Sukses per Kategori

| Kategori | KPI | Target |
| :--- | :--- | :--- |
| **Must Have** | DCDC (Daily Conscious Decision Count) — `PRD §1 North Star` | User membuat ≥1 keputusan sadar/hari via follow-up chip atau capacity warning |
| **Should Have** | Weekly Insight open rate | >40% user membuka `ai_insights` mingguan |
| **Could Have** | Voice brain-dump adoption | >15% task `source = BRAIN_DUMP` via voice (jika dibangun) |
| **Won't Have** | Scope creep | 0 fitur W1-W7 masuk backlog Fase 1-2 tanpa RFC |

---

## 6. Keputusan Desain Penting

1.  **"Mendelegasikan" = Reschedule, bukan Assign ke Orang Lain.** Sesuai `DATABASE §7` `task_suggestions` hanya berisi `suggested_date` + `reason`, bukan `assignee`. Kolaborasi tim adalah produk berbeda.
2.  **Reschedule Selalu Butuh Persetujuan.** `PRD §8` *"auto-reschedule tanpa persetujuan user"* adalah Non-Goal. AI menyarankan, user memutuskan — menjaga *agency*.
3.  **Web Tidak Punya Chat.** `PRD §3.6` — keputusan sadar. Jika user butuh brain-dump, buka Mobile. Ini menjaga fokus Web sebagai *execution surface*.
4.  **Analisis Mendalam = Combined Data.** `DATABASE §12` — `weekly-reflection` tidak hanya lihat `tasks` (DONE/MISSED) tapi juga `conversation_logs` (curhat, kendala, mood). Tanpa chat, insight jadi dangkal.
5.  **Desain Tetap Monokrom Hangat.** Semua UI Must/Should/Could mengikuti `DESIGN.md` — `#FAF9F7` / `#111111` / `#F0EFED`, Inter Black 900 uppercase, no shadows, radius 4-12px.

---

## 7. Next Step untuk Product Designer

- [ ] Validasi M2 *Morning Brief* copy dengan 5 user interview: apakah 3 prioritas cukup atau overload?
- [ ] Prototype M3 follow-up chip interaction (FORGOT/SKIPPED/RESCHEDULED) di Figma — test tap target & wording Bahasa Indonesia
- [ ] Tentukan threshold `daily_capacity_hours` default (PRD: 8.0) — apakah onboarding perlu slider kapasitas?
- [ ] Review C2 *clarify prompt* — kapan `(?)` muncul agar tidak mengganggu flow Daily Focus?

---

# Changelog

| Tanggal | Perubahan |
| :--- | :--- |
| 2026-09-30 | v1 — Initial MoSCoW draft untuk AI Task Management ALUR. Dipetakan ke PRD/technical/DATABASE yang ada. |
