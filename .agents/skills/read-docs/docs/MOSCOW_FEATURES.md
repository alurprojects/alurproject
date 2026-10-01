# ALUR — Penetapan Fitur dengan Metode MoSCoW

> **Tanggal:** 2026-09-30 | **Status:** Final v1 (Integrasi) | **Penulis:** Product Designer (Antigravity + Claude)
> **Cakupan:** Mobile (Flutter) + Web (Next.js) + Backend (FastAPI + LangGraph + Supabase)
> **Sumber Kebenaran:** `PRD.md` · `technical.md` · `DATABASE.md` · `DESIGN.md` · `auth.md`
> **Masalah Inti:**
> 1. Kebingungan menentukan prioritas kerja setiap pagi (*morning decision paralysis*)
> 2. To-do list harian jarang tuntas 100% → tugas tertunda menumpuk tanpa penanganan sistematis
> **Solusi Inti:** AI yang memberi **analisis produktivitas mendalam** + **otomatis menjadwalkan ulang (mendelegasikan) tugas tertunda ke hari lain** — dengan persetujuan user

---

## Ringkasan Eksekutif

Dokumen ini adalah hasil **integrasi dua draft MoSCoW** — draft Antigravity (fokus pada *Honest Capacity* & *Invisible Complexity*) dan draft Claude (fokus pada *granularitas rilis* & *platform mapping*). Keduanya diselaraskan tanpa menghapus nilai unik masing-masing.

| Kategori | Jumlah | Makna |
| :--- | :---: | :--- |
| 🟥 **Must Have** | **13** | Tanpa ini, P1 atau P2 tidak selesai — produk tidak layak rilis |
| 🟧 **Should Have** | **9** | Penting, memperkuat inti — bisa menyusul tepat setelah rilis awal |
| 🟨 **Could Have** | **8** | Nilai tambah / delight — dikerjakan bila waktu & sumber daya cukup |
| ⬜ **Won't Have** | **9** | Sengaja tidak dibangun di siklus ini (Non-Goals `PRD §8`) |

> **Ringkasan satu kalimat:** ALUR v1 wajib menjawab *"mau ngerjain apa dulu pagi ini?"* (Morning Brief + Capacity Check) dan *"gimana kalau tidak tuntas?"* (Auto-Reschedule dengan persetujuan + FORGOT/SKIPPED + Insight mingguan) — semua di atas fondasi Hybrid To-do, Chat Brain-dump, dan keamanan data. Sisanya adalah penguat.

---

## 1. Masalah Pengguna & Prinsip Prioritas

### 1.1 Tiga Masalah yang Dijawab

| # | Masalah | Akar Masalah | Jawaban Produk |
| :-: | :--- | :--- | :--- |
| **P1** | Bingung menentukan prioritas tiap pagi | Terlalu banyak task tanpa pemilah mana yang penting & muat hari ini | **Morning Priority Brief** + **Cek Kapasitas** + **Brain-dump** |
| **P2** | To-do harian jarang tuntas 100% | Rencana tidak realistis + task tertinggal menumpuk tanpa alur | **Nightly MISSED** + **Saran Reschedule 1-tap** + **Capacity Warning** |
| **P3** | Tidak tahu pola kerja sendiri | Tidak ada umpan balik jujur berbasis data | **Insight Mingguan** naratif + **FORGOT vs SKIPPED** + **Deteksi Pola** |

### 1.2 Tiga Filter Invarian ALUR

Diambil dari positioning PRD — *"productivity companion yang secara aktif jujur tentang kapasitas kamu"* (`PRD §1`, `§9`):

| Filter | Pertanyaan Saring |
| :--- | :--- |
| **Honest Capacity** | Apakah fitur ini membuat user jujur soal kapasitas, bukan sekadar *"kamu pasti bisa"*? |
| **Invisible Complexity** | Apakah kompleksitas tetap di backend (LangGraph), frontend tetap sesederhana kertas? |
| **FORGOT vs SKIPPED** | Apakah fitur membedakan *lupa* vs *sengaja skip* sebagai bahan refleksi, bukan label gagal? |

> Sebuah fitur masuk **Must Have** hanya jika **tanpa fitur itu P1 atau P2 tidak terselesaikan**, atau produk tidak bisa berjalan (auth, data, keamanan). Filter di atas menentukan *urutan* di dalam Must Have.

---

## 2. 🟥 MUST HAVE — Wajib Ada (13 Fitur)

> Jika tidak dibangun, user **tetap bingung tiap pagi** dan **tugas tertunda tetap menumpuk**.

| ID | Fitur | Platform | Menjawab | Deskripsi Spesifik | Mapping Teknis | Fase |
| :-: | :--- | :-: | :-: | :--- | :--- | :-: |
| **M1** | **Login Google OAuth** (Supabase Auth, satu metode) | 📱 🌐 | Fondasi | Tanpa akun, tidak ada data per user. Satu metode saja agar sign-up tanpa hambatan. | `auth.md`, Supabase Auth, `users` | 1 |
| **M2** | **Hybrid To-do: Daily Focus + Weekly Overview** | 📱 🌐 | P1, P2 | Default Daily Focus (HARI INI saja), swipe kiri/kanan ganti hari. Toggle ke Weekly accordion Mon–Sun. `+ Add task` inline, checkbox bulat. Mengurangi overload visual. | `PRD §3.2`, `tasks.assigned_date`, `mobile/screens/todo` + `web/app/page.tsx` | 1 |
| **M3** | **Task CRUD Manual + Estimasi Durasi** | 📱 🌐 | P2 | Tambah cepat, centang, edit, hapus. `estimated_minutes` wajib sebagai bahan hitung kapasitas. Tanpa estimasi, "realistis" tidak bisa dihitung. | `tasks` (`estimated_minutes`, `is_ambiguous`), `POST /tasks`, `PATCH /tasks/{id}` | 1 |
| **M4** | **Chat Room: Brain-dump → Task Capture** (Extractor Agent) | 📱 | P1 | Input bebas 1 baris → `Extractor Agent` parse jadi task terstruktur (title, estimated_minutes, ambiguous flag). Friction capture minimal. | `Companion → Extractor → Scheduler` (`technical §5`), `conversation_logs`, `POST /chat/message` | 2 |
| **M5** | **Morning Priority Brief — Top 3 Prioritas** | 📱 🌐 | **P1** | AI susun **maks. 3 task prioritas hari ini** + 1 kalimat alasan per task. Total estimasi Top 3 tidak melebihi `daily_capacity_hours`. Tampil sebagai kartu di puncak Daily Focus + push. Dihitung via cron, bukan on-demand (hindari limit 10s Vercel). | `MorningBriefService` (`technical §6`), `morning_briefs`, cron `morning-brief-generator` (`DATABASE §12`) | 2 |
| **M6** | **Honest Capacity Check + Overload Warning** | 📱 🌐 | P1, P2 | Hitung total `estimated_minutes` hari ini vs `daily_capacity_hours`. Jika overload → warning jujur: *"Beban 9.5 jam, kapasitas 6 jam — mau pindah 2 task ke besok?"* Tidak auto-pindah. | `Scheduler Agent`, `ai_insights.insight_type = CAPACITY_WARNING`, `users.daily_capacity_hours` | 2 |
| **M7** | **Nightly Status Check (PENDING → MISSED)** | ⚙️ | P2 | Cron 00:00 per timezone user: task `PENDING` yang lewat tanggal → `MISSED`. Pemicu seluruh alur reschedule. | `DATABASE §12` cron `nightly-status-check`, `tasks.status` | 3 |
| **M8** | **Saran Reschedule Otomatis (AI usul, user setuju 1-tap)** | 📱 🌐 | **P2** | `Scheduler Agent` buat `task_suggestions` (`suggested_date` + `reason: overload/capacity`) untuk task `goal-linked` atau `recurring`. User tap: `[Pindah hari ini] → RESCHEDULED`, `[Emang skip] → SKIPPED`, `[Udah, lupa centang] → FORGOT`. Hari tujuan selalu dicek sisa kapasitas. | `task_suggestions` (`DATABASE §7`), state machine `missed_follow_up` (`DATABASE §10`) | 3 |
| **M9** | **Follow-up Chip FORGOT / SKIPPED** | 📱 🌐 | P2, P3 | Chip pill (border `Hairline Gray` `DESIGN.md`) pada task MISSED. Membedakan lupa vs sengaja skip — data untuk insight, bukan label gagal. | `tasks.missed_follow_up`, `PATCH /tasks/{id}/follow-up`, `DESIGN §4` | 3 |
| **M10** | **Insight Produktivitas Mingguan** (Reflection Agent) | 📱 🌐 | **P3** | Minggu malam, `Reflection Agent` analisis **combined data** (`tasks` + `conversation_logs` 7 hari) → `ai_insights` (`WEEKLY_REFLECTION` & `PATTERN_DETECTION`). Disajikan sebagai **narasi singkat**, bukan dashboard grafik (Invisible Complexity). | `ai_insights` (`DATABASE §8`), cron `weekly-reflection`, `GET /insights?surfaced=true` | 3 |
| **M11** | **Orchestrator Gatekeeper** | ⚙️ | Semua | Aturan kapan brief/saran/insight boleh muncul — **default diam**. Mencegah AI menjadi noise. Tanpa ini M5, M8, M10 justru membebani. | `Orchestrator` agent (`PRD §5`), `technical §5` graph | 2–3 |
| **M12** | **Capacity Check-in via Chat** | 📱 | P1 | User tanya *"Aku masih bisa ngerjain apa hari ini?"* → `Companion Agent` cek remaining capacity → jawab realistis. Melengkapi M6 dengan jalur percakapan. | `Companion Agent`, `conversation_logs.message_type = CAPACITY_QUERY` | 2 |
| **M13** | **Fondasi Data & Keamanan** | ⚙️ | Fondasi | Skema Supabase, **RLS** di semua tabel, endpoint cron dengan `X-Cron-Secret`, CORS eksplisit. Data task & curhat wajib terlindungi sebelum rilis. | `DATABASE §14`, `technical §7` (`CRON_SECRET`, `JWT_SECRET`) | 1–3 |

> **Definisi Done Must Have:**
> - **M5 Morning Brief** selesai jika: (a) tampil otomatis saat app pertama dibuka tiap hari, (b) berisi maks. 3 task + 1 kalimat alasan, (c) total Top 3 ≤ kapasitas harian, (d) bisa diabaikan tanpa konsekuensi.
> - **M8 Reschedule** selesai jika: (a) AI tidak pernah memindahkan task tanpa persetujuan, (b) hari tujuan selalu punya sisa kapasitas, (c) user bisa Accept/Reject per task, (d) alasan penolakan disimpan.

---

## 3. 🟧 SHOULD HAVE — Sangat Penting, Tidak Menghalangi Rilis Awal (9 Fitur)

> Tanpa ini MVP tetap jalan, tapi pengalaman terasa **kurang cerdas**.

| ID | Fitur | Platform | Deskripsi | Nilai Tambah | Ketergantungan | Fase |
| :-: | :--- | :-: | :--- | :--- | :--- | :--- |
| **S1** | **Companion Agent 2-Tone** (HONEST default, GENTLE saat burnout) | 📱 | Nada lugas & data-driven normal; switch ke GENTLE hanya saat sinyal overload (completion_rate 7 hari, consecutive misses, `mood_detected`). | AI tidak toxic positivity, juga tidak menghakimi saat user down. | M4, M12 | 2–3 |
| **S2** | **Batch Reschedule 1-tap** ("Geser semua sisa hari ini ke besok") | 📱 🌐 | Tombol saat mode GENTLE / overload berat — mempercepat M8 yang per-task. | Mengurangi tap berulang saat user kewalahan. | M8 | 3 |
| **S3** | **Calendar Tab Time-block** (read-only, 06:00–22:00) | 📱 🌐 | Visualisasi tasks dalam blok waktu vertikal + section Unscheduled di atas. Tap → navigasi ke To-do. | User melihat *kapan* task dijadwalkan, membantu reason kapasitas. | M2 | 1 |
| **S4** | **Goals** (hubungkan task ke goal, tampil di Profile) | 📱 | Task bisa punya `goal_id`; list ACTIVE goals di Profile. Prioritas M5 diberi bobot lebih jika terkait goal. | Membuat prioritas lebih bermakna. | M3, M5 | 1 |
| **S5** | **Task Berulang + Weekly Recurrence Generator** | 📱 🌐 | `recurrence_rule` (daily/weekdays/2x-week dll) + cron Minggu malam generate instance baru per `recurrence_group_id`. | Mengurangi input manual habit. | M3 | 3 |
| **S6** | **Push Notification** (Morning Brief & saran reschedule) | 📱 | Notifikasi pagi untuk M5 + pengingat saran M8 yang masih PENDING. | Menghidupkan kebiasaan pagi tanpa harus buka app. | M5, M8 | 3 |
| **S7** | **Deteksi Pola Mendalam** pada Insight | 📱 🌐 | Insight tidak hanya rangkuman, tapi pola: jam paling produktif, hari terberat, jenis task yang sering MISSED. `insight_type = PATTERN_DETECTION`. | Memperdalam M10 dari deskriptif menjadi analitis. | M10 | 3 |
| **S8** | **Kontrol Retensi Chat** (banner, backup, simpan selamanya) | 📱 | Banner *"X riwayat chat >83 hari akan dihapus dalam 7 hari"* → [Unduh Backup] / [Simpan Selamanya] / [Oke, hapus]. | Kepatuhan privasi sebelum rilis publik luas. | M4 | 3 |
| **S9** | **Web Parity** (To-do + Calendar penuh, termasuk Task Edit Modal) | 🌐 | Web v1 setara mobile untuk eksekusi — tanpa Chat & Profile (keputusan sadar `PRD §3.6`). | Layar perencanaan besar yang konsisten. | M2, S3 | 1–2 |

---

## 4. 🟨 COULD HAVE — Nilai Tambah (8 Fitur)

> Dikerjakan jika waktu/sumber daya berlebih. Tidak memengaruhi janji inti produk.

| ID | Fitur | Platform | Deskripsi | Catatan |
| :-: | :--- | :-: | :--- | :--- |
| **C1** | **Google Calendar Read-Only Sync** | 📱 🌐 | `calendar.readonly` OAuth — tarik events untuk kalkulasi waktu kosong. Kapasitas lebih akurat. | `PRD` Tahap B. Meningkatkan M6 & M8. |
| **C2** | **Voice-to-Text Brain Dump** | 📱 | Mic di Chat Room → Whisper/Gemini Audio → teks → pipeline Extractor. | `technical §1` Fase 3. Capture sambil jalan. |
| **C3** | **Clarify Prompt untuk Task Ambigu** | 📱 🌐 | Task tanpa `estimated_minutes` (`is_ambiguous = TRUE`) tampil `(?)` → tap → inline *`Berapa lama kira-kira?`* → `PATCH /clarify`. | Meningkatkan akurasi M6. |
| **C4** | **Hierarchical Memory (Core Profile Condenser)** | ⚙️ | Cron harian ringkas chat jadi `users.ai_profile_summary` JSON (~50 token) yang selalu di-inject ke prompt Companion. | `technical §6` — hemat token, personalisasi tanpa history raksasa. |
| **C5** | **RAG Semantic Retrieval (pgvector)** | ⚙️ | `embeddings` vector(768) + `match_embeddings` RPC. Companion bisa jawab *"Minggu lalu kamu juga bilang burnout Senin"* dengan grounding. | `DATABASE §8.6` Fase 3. |
| **C6** | **Someday Drawer** (backlog belum terjadwal) | 🌐 | Menampung ide tanpa mengotori jadwal harian. | Alternatif ringan web. |
| **C7** | **Dark Mode** | 📱 🌐 | Menambah kenyamanan, perlu penyesuaian token palet hangat `#FAF9F7`/`#111111`. | `DESIGN.md` — bukan prioritas MVP. |
| **C8** | **Ekspor / Bagikan Ringkasan Mingguan** (PDF/gambar) | 📱 🌐 | Berguna untuk refleksi pribadi atau share ke mentor. | Butuh M10 stabil dulu. |

> **Catatan integrasi:** `Brain Dump Modal` multi-tugas di web, `Detail task kaya` (subtask/catatan/warna), dan `Tuning kepribadian adaptif` dari draft Claude dilebur ke C3–C5/C6 — tetap tercatat sebagai backlog Could Have yang bisa dipecah saat grooming.

---

## 5. ⬜ WON'T HAVE (Kali Ini) — Sengaja Tidak Dibangun (9 Fitur)

> Disebut eksplisit agar tidak terjadi *scope creep*. Selaras dengan `PRD §8 Non-Goals`.

| ID | Fitur yang DITOLAK | Alasan Penolakan | Alternatif yang Disediakan |
| :-: | :--- | :--- | :--- |
| **W1** | **Auto-reschedule TANPA persetujuan user** | Melanggar *human-in-the-loop*. ALUR jujur, bukan mengambil alih keputusan. | `task_suggestions` PENDING → user Accept/Reject 1-tap |
| **W2** | **Dashboard & grafik analitik penuh** | Bertentangan dengan *Invisible Complexity*. Frontend tetap sesederhana kertas. | `ai_insights` naratif (M10) + FORGOT/SKIPPED distinction |
| **W3** | **Gamifikasi** (streak, leaderboard, level, XP) | Non-Goal PRD — mendorong tekanan, bukan realisme. | Refleksi jujur + capacity warning |
| **W4** | **Harada Method / 8-Pilar** | Non-Goal PRD — di luar masalah pengguna general 18–35. | Goals sederhana + AI reflection ringan |
| **W5** | **Personalisasi gaya belajar** (`learning_style`) | Non-Goal PRD — bukan aplikasi edukasi. | `ai_profile_summary` hanya untuk gaya kerja & kapasitas |
| **W6** | **Chat Room & Profile di Web v1** | Keputusan sadar `PRD §3.6` — menunggu mobile stabil. | Mobile Chat Room penuh; Web fokus eksekusi |
| **W7** | **Kolaborasi tim / berbagi task** (delegasi ke orang lain) | Target v1 adalah individu. Kata "mendelegasikan" pada brief = reschedule ke hari lain, bukan assign ke user lain. | `suggested_date` + `reason` |
| **W8** | **Integrasi pihak ketiga lain** (Notion, Todoist, Slack) & **write** ke Google Calendar | Menambah permukaan kerja & risiko sebelum inti terbukti. | Tahap B hanya GCal read-only (C1) |
| **W9** | **Login Email + Password** | Sengaja dihapus untuk menyederhanakan MVP (`auth.md` — zero password). | Google OAuth satu metode (M1) |

---

## 6. Peta Fitur terhadap Masalah

```
P1  Bingung prioritas tiap pagi ──► M5 Morning Brief ── M6 Capacity Check ── M4 Brain-dump ── M12 Capacity Chat
                                      └─ diperkuat: S4 Goals, S6 Push, C1 Google Calendar, S1 Nada GENTLE

P2  To-do jarang tuntas ─────────► M6 Capacity Check ── M7 Nightly MISSED ── M8 Reschedule ── M9 FORGOT/SKIPPED
                                      └─ diperkuat: S2 Batch Reschedule, S5 Recurrence, S3 Calendar, C3 Clarify

P3  Tidak paham pola sendiri ────► M10 Insight Mingguan ── M9 FORGOT/SKIPPED
                                      └─ diperkuat: S7 Deteksi Pola, S1 Nada GENTLE, C5 RAG, C4 Hierarchical Memory

Fondasi ─────────────────────────► M1 Auth ── M2 Hybrid To-do ── M3 CRUD+Estimasi ── M11 Orchestrator ── M13 RLS/Keamanan
                                      └─ diperkuat: S9 Web Parity, S8 Retensi Chat
```

---

## 7. Prioritisasi Visual

```
Value Tinggi
    ▲
    │  M5 Morning Brief          S7 Deteksi Pola
    │  M8 Auto-Reschedule  ●     S1 2-Tone Companion
    │  M6 Capacity Warn    ●
    │  M4 Brain-dump       ●     S4 Goals
    │  M2 Hybrid To-do     ●     S6 Push
    │                            S3 Calendar
    │                            C1 GCal Sync
    │  W1–W9 (Won't Have)        C2 Voice
    │                            C3 Clarify
    │                            C5 RAG
    └──────────────────────────────────────────►
         Effort Rendah              Effort Tinggi

● Must Have  = kuadran kiri-atas (value maksimal, effort terukur)
  Should/Could = penguat yang dijadwalkan setelah inti terbukti
```

---

## 8. Urutan Rilis yang Disarankan (Selaras `PRD §7`)

| Rilis | Fase PRD | Isi MoSCoW | Hasil bagi Pengguna |
| :--- | :--- | :--- | :--- |
| **R1 — Fondasi** | Fase 1 UI Core | **M1, M2, M3, M13** + S3 (sebagian), S4, S9 | To-do rapi di mobile & web. Validasi desain tanpa AI. Chat Room sebagai shell kosong. |
| **R2 — Prioritas Pagi** | Fase 2 Chat + LangGraph | **M4, M5, M6, M11, M12** + S1 | Pagi tidak lagi bingung: ada Top 3 + warning overload + brain-dump. |
| **R3 — Reschedule & Insight** | Fase 3 Otonomi Penuh | **M7, M8, M9, M10** + S2, S5, S7 | Task tertunda dipindah otomatis dengan persetujuan + pola mingguan. |
| **R4 — Penyempurnaan** | Fase 3 lanjutan | **S6, S8** + C1–C8 (bertahap) | Notifikasi, privasi, kalender penuh, delight features. |
| **Tahap B** | — | C1 (GCal read-only) | Kapasitas dikurangi meeting aktual. |
| **Backlog** | — | Sisa Could Have | Berdasarkan umpan balik pengguna. |

---

## 9. Metrik Keberhasilan

| Masalah | Metrik | Target Awal | Sumber Data |
| :--- | :--- | :--- | :--- |
| P1 | % user yang membuka Morning Brief & mengerjakan ≥1 dari Top 3 | ≥ 60% hari aktif | `morning_briefs.opened_at` + `tasks.status` |
| P2 | Completion rate harian (DONE ÷ terjadwal) | Naik ≥ 20% vs 2 minggu pertama | `tasks` |
| P2 | Acceptance rate saran reschedule | ≥ 50% | `task_suggestions.status` |
| P3 | % user yang membaca insight mingguan | ≥ 40% | `ai_insights.surfaced` |
| Semua | **DCDC** (Daily Conscious Decision Count) — North Star `PRD §1` | Tren naik mingguan | Follow-up chip + capacity warning taps |
| Fondasi | Scope creep W1–W9 masuk backlog Fase 1–2 tanpa RFC | 0 | Backlog audit |

---

## 10. Keputusan Desain yang Perlu Dikonfirmasi

1. **"Otomatis" vs Non-Goal auto-reschedule.** Brief meminta reschedule otomatis, PRD melarang tanpa persetujuan. Dokumen ini menyelaraskannya menjadi ***otomatis diusulkan, dieksekusi setelah 1 tap setuju***. Jika ingin benar-benar otomatis, `PRD §8` harus direvisi.

2. **"Analisis mendalam" vs Invisible Complexity.** Kedalaman ditaruh di backend (pola dari `tasks` + `conversation_logs`), tampilannya berupa **narasi singkat** (M10). Dashboard penuh dikeluarkan (W2).

3. **Morning Brief belum ada di PRD lama — sekarang sudah ada.** `morning_briefs` table (`DATABASE §8.7`), `MorningBriefService` (`technical §6`), dan cron `morning-brief-generator` sudah ditambahkan. M5 tidak lagi butuh revisi PRD terpisah.

4. **Batas waktu backend (Vercel 10s).** M5, M8, M10 memanggil LLM — hasil **dihitung sebelumnya via cron** lalu disajikan dari database, bukan dihitung saat user membuka app. Pola batching sudah ada di `technical §5` dan `DATABASE §11`.

5. **"Mendelegasikan" = Reschedule, bukan assign ke orang lain.** `task_suggestions` hanya berisi `suggested_date` + `reason`, bukan `assignee`. Kolaborasi tim adalah produk berbeda (W7).

6. **Web tanpa Chat adalah keputusan sadar** (`PRD §3.6`), bukan keterbatasan teknis. Jika user butuh brain-dump, buka Mobile.

7. **Desain tetap monokrom hangat.** Semua Must/Should/Could mengikuti `DESIGN.md` — `#FAF9F7` / `#111111` / `#F0EFED`, Inter Black 900 uppercase, no shadows, radius 4–12px.

---

## 11. Next Step untuk Product Designer

- [ ] Validasi copy **M5 Morning Brief** dengan 5 user interview: apakah 3 prioritas cukup atau overload?
- [ ] Prototype interaksi **M9 follow-up chip** (FORGOT/SKIPPED/RESCHEDULED) di Figma — test tap target & wording Bahasa Indonesia
- [ ] Tentukan threshold `daily_capacity_hours` default (8.0) — apakah onboarding perlu slider kapasitas?
- [ ] Review **C3 clarify prompt** — kapan `(?)` muncul agar tidak mengganggu flow Daily Focus?
- [ ] Grooming backlog **C4 Hierarchical Memory** & **C5 RAG**: urutan mana dulu saat Fase 3 dimulai?

---

## Changelog

| Tanggal | Versi | Perubahan |
| :--- | :--- | :--- |
| 2026-09-30 | v1 (Antigravity) | Draft awal 6 Must / 6 Should / 6 Could / 7 Won't — fokus Honest Capacity & mapping teknis. (`plans/2026-09-30_moscow-ai-task-manager.md`) |
| 2026-09-30 | v1 (Claude) | Draft 12 Must / 9 Should / 8 Could / 9 Won't — fokus granularitas rilis & platform mapping. (`from_llm/MOSCOW_FEATURES_CLAUDE.md`) |
| **2026-09-30** | **v1 Final (Integrasi)** | **Gabungan kedua draft → `MOSCOW_FEATURES.md`**: 13 Must (tambah M12 Capacity Chat, M13 Keamanan), 9 Should, 8 Could, 9 Won't. Struktur, peta masalah, roadmap R1–R4, dan metrik disatukan. |

---

> **File ini adalah Single Source of Truth MoSCoW untuk ALUR.** Perubahan prioritas selanjutnya wajib update file ini (bukan file di `from_llm/` atau `plans/`).
