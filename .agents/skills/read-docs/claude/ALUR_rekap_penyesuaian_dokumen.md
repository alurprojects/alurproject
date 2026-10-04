# ALUR — Rekap Penyesuaian Dokumen

> **Tanggal:** 2026-10-03
> **Cakupan:** 11 file markdown ALUR (`PRD`, `MOSCOW_FEATURES`, `DATABASE`, `technical`, `DESIGN`, `DESIGN-WEB`, `auth`, `mindmap`, `DEPLOYMENT_GUIDE`, `ENV_GUIDE`, `feedback`)
> **Dasar:** (1) dua keputusan baru: *Goal Breakdown* dan penggantian istilah *To-do* menjadi *Target Harian*; (2) saran audit sebelumnya; (3) temuan konsistensi saat membaca semua file.
> **Status:** usulan. Semua angka dan ambang adalah **hipotesis untuk divalidasi**, bukan fakta.

**Legenda**

| Tanda | Arti |
| :--- | :--- |
| 🆕 | Dampak keputusan baru (Goal Breakdown / Target Harian) |
| 🔁 | Berasal dari audit dan saran sebelumnya |
| 🔧 | Temuan konsistensi antar dokumen |
| **P0** | Putuskan/ubah sebelum fitur baru dikerjakan |
| **P1** | Selesaikan sebelum rilis fitur terkait |
| **P2** | Rapikan bila sempat |

---

## 1. Keputusan Baru dan Posisi Saya

### 1.1 Goal Breakdown: tujuan dan penyesuaian posisi

**Tujuan (dari kamu):** pengguna tidak perlu mengisi to-do manual dari nol. Dari goal, AI mengisi Target Harian di tiap hari supaya tidak kosong. Pengguna tetap bebas menambah tugas sendiri.

**Penyesuaian dari jawaban saya sebelumnya.** Sebelumnya saya menyarankan goals bukan bagian onboarding wajib. Alasan kamu (mencegah hari kosong di awal) valid, dan ada argumen struktural yang mendukungnya: **Morning Brief (M5) hanya bisa memprioritaskan tugas yang sudah ada**. Hari pertama yang kosong berarti P1 belum terjawab. Posisi yang disarankan sekarang:

| Aspek | Posisi sebelumnya | Posisi sekarang |
| :--- | :--- | :--- |
| Letak di alur | Setelah Morning Brief pertama | **Langkah onboarding setelah login**, tapi **bisa dilewati** |
| Jika dilewati | Tidak dibahas | Jalur cadangan: *brain-dump* satu kalimat lewat pipeline M4 (sudah ada) |
| Persetujuan | Per tugas | **Satu kali untuk seluruh rencana**, lalu bisa edit per tugas |
| Isi hari | Rolling window | Tetap rolling window (7 hari), **bukan** seluruh horizon goal |

**Aturan yang tetap dipertahankan (agar tidak melanggar Honest Capacity dan W1):**

1. AI **mengusulkan**, pengguna **menerima rencana** sebelum tugas masuk ke `tasks`.
2. Isi per hari dibatasi kapasitas. Usulan awal: tugas dari goal ≤ 70–80% kapasitas harian, sisanya untuk tugas manual dan brain-dump *(hipotesis)*.
3. Hanya 7 hari ke depan yang dimaterialisasi. Sisanya hanya milestone.
4. Tugas buatan pengguna tidak pernah ditimpa AI.
5. Jika rencana tidak muat, AI menyampaikannya jujur dan menawarkan: geser deadline, kurangi lingkup, atau kurangi komitmen lain.

**Alur onboarding yang diusulkan** (target total ≤ 2 menit *(hipotesis)*):

```text
1. Login Google (auth.md)
2. Kapasitas: jam efektif per hari + jam tetap yang tidak bisa diganggu (opsional)
3. Goal (opsional): judul + deadline (opsional) + jam per minggu (opsional)
   └─ [Lewati — tulis saja hal yang ada di kepalamu] → jalur brain-dump (M4)
4. Draft Rencana: milestone + 7 hari pertama
   └─ [Terima rencana] [Edit] [Hanya milestone, tugasnya nanti]
5. MainScreen → Target Harian sudah terisi + Morning Brief hari itu
```

**Setelah onboarding:** rencana diperbarui tiap Minggu malam (*rolling replan*) berdasarkan progres nyata. Hanya tugas `ai_generated`, `PENDING`, tanggal ke depan, dan belum diubah pengguna yang boleh diganti.

### 1.2 Target Harian: istilah dan catatan desain

**Alasan penggantian (dari kamu):** "to-do list" terlalu sederhana dan tidak mewakili masalah yang diselesaikan. Setuju dengan arahnya. Masalah ALUR adalah *komitmen yang realistis*, bukan sekadar *daftar ingatan*.

**Definisi kerja:** **Target Harian = komitmen realistis untuk satu hari: kumpulan tugas yang dijadwalkan pada tanggal itu dan muat dalam kapasitas.**

**Tiga risiko yang perlu dikelola:**

| Risiko | Mengapa penting | Mitigasi |
| :--- | :--- | :--- |
| **Tumpang tindih "Goal" vs "Target"** | Dalam bahasa Indonesia keduanya hampir sinonim. Pengguna bisa bingung mana yang jangka panjang | Hierarki tetap: *Goal → Milestone → Target Harian → Tugas*. Tulis di glosarium PRD |
| **Konotasi tekanan** | "Target tidak tercapai" terasa seperti kegagalan, padahal FORGOT vs SKIPPED justru dirancang bukan sebagai label gagal | Tugas tak selesai disebut **Terlewat** (bukan "gagal/tidak tercapai"). Tone GENTLE tidak memakai kata "target" saat menyebut kegagalan |
| **Tumpang tindih dengan Top 3** | Morning Brief juga memilih "prioritas" | Top 3 = **Prioritas Pagi**, subset dari Target Harian, bukan daftar terpisah |

**Rekomendasi:** pakai **"Target Harian"** sebagai nama layar/tab, tetapi **uji dulu dengan 5–8 orang** terhadap dua alternatif (lihat 2.2). Satuan itemnya tetap **"tugas"** ("3 dari 5 tugas selesai") agar tidak berat.

**Jangan ganti identifier teknis.** Tabel `tasks`, endpoint `/tasks`, key `preferences.todo_default_view` tetap. Penggantian hanya di UI dan dokumen. Mengganti skema tidak memberi manfaat bagi pengguna dan menambah risiko migrasi.

---

## 2. Spesifikasi Ringkas sebagai Dasar Penyesuaian

### 2.1 Glosarium (usulan untuk PRD Lampiran A)

| Istilah UI | Definisi | Identifier teknis | Catatan |
| :--- | :--- | :--- | :--- |
| **Goal** | Tujuan jangka menengah-panjang | `goals` | Dibuat lewat onboarding atau Profile |
| **Milestone** | Tahap antara menuju goal | `goals.plan` (JSONB) | Tidak jadi tabel sendiri di v1 |
| **Target Harian** | Komitmen realistis satu hari | `tasks` dengan `assigned_date` = hari itu | Nama tab: **Target** |
| **Tugas** | Satu item dalam Target Harian | baris `tasks` | Satuan, bukan "target" |
| **Prioritas Pagi (Top 3)** | Maks. 3 tugas yang disarankan AI hari itu | `morning_briefs.content` | Subset Target Harian |
| **Draft Rencana** | Usulan breakdown yang belum diterima | `goals.plan_draft`, `plan_status = DRAFT` | Tidak ada di `tasks` sebelum diterima |
| **Terlewat** | Tugas tak selesai di akhir hari | `status = MISSED` | Hindari kata "gagal" |
| **Kapasitas** | Jam efektif tersedia per hari | `daily_capacity_hours` − `preferences.fixed_blocks` | Dasar Capacity Warning |

### 2.2 Uji istilah (copy test)

| Kandidat | Kelebihan | Risiko |
| :--- | :--- | :--- |
| **Target Harian** (pilihan kamu) | Selaras hierarki goal, menyiratkan komitmen | Terasa menekan, mirip "Goal" |
| **Fokus Hari Ini** | Tenang, selaras "Daily Focus" yang sudah ada | Kurang menyiratkan komitmen |
| **Rencana Hari Ini** | Netral, cocok positioning *Realistic Planner* | Terdengar seperti jadwal, bukan prioritas |

Pertanyaan uji: *"Apa yang kamu harapkan ada di layar ini?"* dan *"Apakah nama ini terasa menekan saat ada yang terlewat?"*

### 2.3 Keputusan desain data (dasar perubahan DATABASE/technical)

| Kebutuhan | Pilihan yang disarankan | Alasan |
| :--- | :--- | :--- |
| Menyimpan milestone dan draft | **JSONB di `goals`** (`plan`, `plan_draft`), bukan tabel baru | Lebih sederhana; tidak ada RLS baru. Pecah jadi tabel bila milestone butuh status sendiri |
| Draft rencana | **Jangan simpan sebagai `tasks`** | Cron nightly akan menandai draft `PENDING` sebagai `MISSED` dan merusak hitungan kapasitas |
| Asal tugas | Tambah `task_source = GOAL_PLAN` | Memisahkan dari `CHAT_ROOM`, dibutuhkan untuk metrik |
| Melindungi edit pengguna saat replan | Kolom `tasks.user_modified` | Replan tidak boleh menimpa tugas yang sudah disentuh pengguna |
| Jam tetap pekerja | `users.preferences.fixed_blocks` (JSONB) | Tanpa migrasi skema |
| Waktu generate | **Asinkron** (`plan_status`: `GENERATING → DRAFT → ACCEPTED`) | Batas 10 detik Vercel; polanya sama dengan M5 (hitung dulu, sajikan dari DB) |

---

## 3. Rekap Penyesuaian per File

### 3.1 `PRD.md`

| # | Lokasi | Tanda | Prioritas | Penyesuaian |
| :-: | :--- | :-: | :-: | :--- |
| 1 | §1 Visi | 🔁 | P0 | Tambah **Problem Statement** dan P1–P3 (saat ini hanya ada di `mindmap.md` dan MoSCoW). Tambah JTBD |
| 2 | §1 Target user | 🔁 | P0 | Ganti "General Productivity 18-35, siapa saja yang overwhelmed" dengan **segmen berbasis situasi** dan *beachhead* (freelancer / pekerja awal karier dengan side project; mahasiswa tingkat akhir sebagai segmen kedua) |
| 3 | §1 North Star | 🔁 | P0 | Beri **definisi operasional DCDC** + guardrail (retensi D7/D30, opt-out saran, tap asal-asalan). Tulis *baseline* diukur 2 minggu pertama beta |
| 4 | §1 Positioning | 🔁 | P1 | Tambah **USP**: ALUR proaktif dan jujur tentang kapasitas, berbeda dari asisten umum yang reaktif. Beri catatan: klaim kompetitor harus diverifikasi sebelum dipublikasikan |
| 5 | §1 Prinsip | 🆕 | P0 | Tambah prinsip **"hari tidak boleh kosong di awal"** (aktivasi), terhubung ke Goal Breakdown |
| 6 | §2 Core Concept | 🆕 | P0 | "To-do List" → **"Target Harian"**. Tambah sumber ketiga yang mengisinya: **Goals**. Dua saluran lama tetap |
| 7 | **Baru §3.0** Onboarding | 🆕 | P0 | Tambah alur onboarding (lihat 1.1): kapasitas → goal opsional → draft rencana → MainScreen. Sertakan jalur "Lewati" |
| 8 | §3.1 Navigasi | 🆕 | P0 | Tab "To-do" → **"Target"**. Fungsi: "Hybrid Target Harian" |
| 9 | §3.2 | 🆕 | P0 | Ubah judul jadi **Target Harian Tab (Hybrid View)**. Tambah: (a) *empty state* + teks; (b) label asal tugas AI ("dari Goal: …"); (c) satu baris meta kapasitas ("4 dari 6 jam"), bukan grafik (W2); (d) hubungan dengan Prioritas Pagi. "Daily Focus"/"Weekly Overview" boleh dilokalkan jadi "Hari Ini"/"Minggu Ini" (opsional) |
| 10 | §3.3 Chat Room | 🆕 | P1 | Catat: di v1 goal dibuat **lewat UI** (onboarding/Profile), bukan deteksi otomatis di chat. Deteksi goal dari chat → backlog Could. Chat tetap jadi jalur cadangan onboarding (brain-dump) |
| 11 | §3.4 Calendar | 🔁 | P1 | Beri alasan masalah yang dijawab (visual kapasitas untuk P1) atau turunkan prioritasnya. Ganti "navigasi ke To-do tab" → "Target Harian" |
| 12 | §3.5 Profile | 🆕 | P1 | Goal: tambah detail (milestone, status rencana, [Susun ulang rencana]). Settings: tambah **jam tetap** selain `daily_capacity_hours` (agar kapasitas tidak salah hitung bagi pekerja) |
| 13 | §3.6 Web | 🔁 | P0 | Selaraskan dengan `DESIGN-WEB.md`: tegaskan tidak ada BrainDumpModal (ganti quick-add satu baris). Web *empty state* mengarahkan ke mobile untuk mengatur goal (lihat keputusan terbuka K3) |
| 14 | §4 Data Model | 🆕 | P0 | `goals`: + `target_hours_per_week`, `definition_of_done`, `plan`, `plan_draft`, `plan_status`, `last_replanned_at`. `tasks`: + `user_modified`, `source` + `GOAL_PLAN`. `users.preferences`: + `fixed_blocks`, `onboarding_completed_at` |
| 15 | §5 Agent | 🆕 | P1 | Tambah peran **Goal Planner** (node baru di graph, memakai persona Clarifier) + validasi kapasitas berbasis aturan (bukan LLM). Orchestrator: aturan tampil rencana = sekali saat onboarding, lalu mingguan, default diam |
| 16 | §5 Cron | 🆕 | P1 | Tambah langkah **replan goal mingguan**. Sarankan digabung ke job Minggu malam yang ada agar tidak menambah beban batch |
| 17 | §6 Core Flows | 🆕 | P1 | Tambah flow **Goal Setup & Breakdown**. Ganti "Eksekusi Harian: … To-do tab" → Target Harian |
| 18 | §7 Fase | 🆕 | P1 | Fase 1: "Hybrid Daily/Weekly to-do" → Target Harian; goals manual tetap di Fase 1. Breakdown AI masuk **setelah R2** (usulan: R2b, lihat 3.2 baris 9) |
| 19 | §8 Non-Goals | 🆕 | P1 | Tegaskan: (a) tidak ada isi hari otomatis **tanpa persetujuan rencana**; (b) breakdown linear dengan rolling window, **bukan** Harada/8-Pilar; (c) goal bukan manajemen proyek (tanpa Gantt/dependency) |
| 20 | §9 Differentiators | 🔁 | P1 | Tambah #4 **Proaktif** (brief dan tinjauan malam tanpa diminta) |
| 21 | **Baru Lampiran A** | 🆕 | P0 | Glosarium (tabel 2.1) |
| 22 | **Baru** Asumsi & Risiko | 🔁 | P1 | Cold start, privasi curhat, latency AI, ketergantungan pada kualitas estimasi durasi |

### 3.2 `MOSCOW_FEATURES.md`

| # | Lokasi | Tanda | Prioritas | Penyesuaian |
| :-: | :--- | :-: | :-: | :--- |
| 1 | Header "Masalah Inti" no. 2 | 🆕 | P1 | "To-do list harian jarang tuntas" → "Target harian jarang tuntas" |
| 2 | Header versi/tanggal | 🆕 | P1 | Naikkan ke v1.1, update tanggal |
| 3 | **Baru M14** | 🆕 | P0 | **M14 — Goal Setup & AI Breakdown (Onboarding)**. Menjawab P1 (hari pertama tidak kosong, M5 punya bahan). Dependensi: M3 (estimasi), M6 (kapasitas), M11 (gatekeeper). Fase: manual di 1, AI di R2b |
| 4 | S4 Goals | 🆕 | P0 | **Dilebur ke M14** (tandai tombstone: "dilebur ke M14"). Alasan: Must tidak boleh bergantung pada Should |
| 5 | Ringkasan Eksekutif | 🆕 | P0 | Hitungan **13/9/8/9 → 14/8/8/9** (total tetap 39). Perbarui juga di `mindmap.md` |
| 6 | M2 | 🆕 | P1 | "Hybrid To-do" → "Hybrid Target Harian" |
| 7 | M5 Definition of Done | 🆕 | P1 | Tambah bahwa bobot prioritas memperhitungkan tugas terkait goal |
| 8 | §3 S3, S9 | 🆕/🔁 | P1 | S3: "navigasi ke To-do" → Target Harian. S9: **Task Edit Modal penuh** bertentangan dengan Invisible Complexity; pangkas sesuai 3.6 |
| 9 | §8 Urutan Rilis | 🆕 | P0 | Karena R2 sudah live (`mindmap.md`), jangan masukkan M14 ke R2 secara retroaktif. Tambah baris **R2b — Aktivasi** (M14 AI breakdown + onboarding) di antara R2 dan R3 |
| 10 | §9 Metrik | 🆕/🔁 | P1 | DCDC: ganti "chip + capacity warning taps" dengan definisi lengkap. Tambah metrik M14: breakdown acceptance rate, edit rate, completion rate tugas goal vs tugas manual, % pengguna masih punya goal aktif di D28. **Ambang diisi setelah baseline** |
| 11 | §10 Keputusan | 🆕 | P1 | Tambah: (a) "Isi otomatis" vs W1 diselesaikan lewat **persetujuan rencana satu kali**; (b) istilah Target Harian; (c) M14 menggantikan S4 |
| 12 | §11 Next Step | 🆕/🔁 | P1 | Tambah: wizard-of-oz goal breakdown (H5), copy test istilah (H6), tentukan default kapasitas dan jam tetap di onboarding |
| 13 | §5 W4 | 🆕 | P2 | Perjelas batas: breakdown goal ≠ Harada |
| 14 | §4 catatan integrasi | 🔧 | P1 | "Brain Dump Modal multi-tugas di web" ke Could bertentangan dengan `PRD §3.6`/W6. Selaraskan |
| 15 | Changelog | 🆕 | P1 | Tambah entri v1.1 |

### 3.3 `DATABASE.md`

| # | Lokasi | Tanda | Prioritas | Penyesuaian |
| :-: | :--- | :-: | :-: | :--- |
| 1 | §1 deskripsi `goals` | 🆕 | P1 | Tambah: sumber breakdown ke tugas harian |
| 2 | §1 deskripsi `morning_briefs` | 🆕 | P2 | "banner to-do pagi" → "banner Target Harian" |
| 3 | §3 `users.preferences` | 🆕 | P0 | Tambah `fixed_blocks`, `onboarding_completed_at`. Pertahankan key `todo_default_view` |
| 4 | §4 `goals` | 🆕 | P0 | Tambah kolom: `target_hours_per_week NUMERIC`, `definition_of_done TEXT`, `plan JSONB`, `plan_draft JSONB`, `plan_status` (enum `NONE/GENERATING/DRAFT/ACCEPTED`), `last_replanned_at TIMESTAMPTZ` |
| 5 | §5 `tasks` | 🆕 | P0 | `task_source` + `GOAL_PLAN`; kolom `user_modified BOOLEAN DEFAULT FALSE`. Tambah aturan bisnis: replan hanya menyentuh `ai_generated AND status='PENDING' AND assigned_date > CURRENT_DATE AND NOT user_modified` |
| 6 | §5 penjelasan `goal_id` | 🆕 | P1 | Konsekuensi: tugas hasil breakdown otomatis `goal-linked` sehingga masuk alur follow-up FORGOT/SKIPPED. Tugas lepas tetap tanpa chip (lihat K4) |
| 7 | §8.7 `morning_briefs.content` | 🆕 | P2 | Opsional: tambah `goal_context` agar Top 3 bisa menjelaskan keterkaitan goal |
| 8 | §12 Cron | 🆕 | P1 | Tambah langkah replan goal (gabung dengan job mingguan atau job baru). Tetap lewat `X-Cron-Secret` |
| 9 | §13 Migrasi | 🆕 | P0 | Tambah `017_add_goal_planning.sql`. Catatan: `ALTER TYPE … ADD VALUE` — nilai baru tidak bisa dipakai dalam transaksi yang sama, jalankan terpisah |
| 10 | §14 Checklist RLS | 🆕 | P2 | Tidak ada tabel baru bila JSONB dipakai. Bila memilih tabel `goal_milestones`, tambah RLS |
| 11 | §4 kalimat pembuka | 🆕 | P2 | "bisa di-breakdown" → jelaskan mekanismenya (rencana → diterima → `tasks`) |

### 3.4 `technical.md`

| # | Lokasi | Tanda | Prioritas | Penyesuaian |
| :-: | :--- | :-: | :-: | :--- |
| 1 | Paragraf pembuka | 🆕/🔁 | P1 | "Hybrid To-do" → Target Harian; "berusia 18-35" → profil berbasis situasi |
| 2 | §2 Aliran Utama no. 6 | 🆕 | P1 | "To-do list harian" → "Target Harian" |
| 3 | §3 Struktur repo | 🆕 | P1 | Tambah `screens/onboarding/` dan `screens/goals/`. Folder `todo/` boleh tetap (nama internal) |
| 4 | §4 API: **Goals** | 🆕 | P0 | **Saat ini tidak ada endpoint Goals sama sekali.** Tambah: `POST/GET/PATCH/DELETE /goals`, `POST /goals/{id}/plan` (202, asinkron), `GET /goals/{id}/plan` (status + draft), `POST /goals/{id}/plan/accept` |
| 5 | §4 API: Settings | 🔧 | P0 | Setting Profile (`daily_capacity_hours`, jam tetap, timezone, onboarding) tidak punya endpoint di dokumen ini. Tambah mis. `PATCH /users/me/preferences` |
| 6 | §5 LangGraph | 🆕 | P1 | Tambah node `goal_planner` (persona Clarifier) → `validate_capacity` (aturan, bukan LLM, sejalan `validate_ambiguity`) → simpan `plan_draft`. State: `goal_id`, `goal_plan_draft` |
| 7 | §5 Batching cron | 🆕 | P1 | Jelaskan replan mingguan ikut pola batch yang ada |
| 8 | §6 Companion | 🆕 | P2 | Persona Clarifier dipakai untuk klarifikasi goal. `GOAL_CAPTURE` sebagai `message_type` ditunda (deteksi goal di chat = Could) |
| 9 | §8 Testing | 🆕 | P1 | Tambah uji: (a) total tugas hasil breakdown per hari ≤ kapasitas efektif; (b) draft tidak ikut nightly MISSED; (c) replan tidak menimpa `user_modified`; (d) set uji 10 goal contoh untuk kualitas breakdown |
| 10 | §10 Observability | 🆕 | P2 | Log acceptance/edit rate breakdown dan latensi `/goals/{id}/plan` |
| 11 | §9 Deployment | 🔧 | P1 | Konsisten dengan `DEPLOYMENT_GUIDE.md` (Vercel Tahap 1). Lihat 3.10 untuk penanganan `feedback.md` |

### 3.5 `DESIGN.md`

| # | Lokasi | Tanda | Prioritas | Penyesuaian |
| :-: | :--- | :-: | :-: | :--- |
| 1 | §4 Bottom Navigation | 🆕 | P0 | Tab 1 "To-do" → **"Target"**. Pertimbangkan ikon: checklist tetap atau target/flag outline (uji di copy test) |
| 2 | §4 Follow-up Chip | 🔧 | P1 | Tertulis "kapsul (pill)" padahal **CONST-03** melarang kapsul penuh (999px) kecuali FAB. Tetapkan radius maks. 12px |
| 3 | §4 Komponen baru | 🆕 | P0 | Tambah: **Plan Preview Card** (Paper Gray, radius 8–12px, tanpa shadow), **label asal tugas AI** ("dari Goal: …"), **Empty State** Target Harian, **layar onboarding** (kapasitas, goal, draft rencana) |
| 4 | §4 Task Row | 🆕 | P1 | Tambah state: tugas AI vs manual; baris meta kapasitas |
| 5 | §7 Motion | 🆕 | P1 | Tambah transisi Onboarding → MainScreen dan penerimaan rencana. Tetap *quiet motion* (≤350ms, tanpa bounce) |
| 6 | §1 vs `auth.md` | 🔧 | P1 | §1 menyatakan **tanpa gradasi**, sementara `auth.md` memakai radial gradient pastel. Putuskan satu (lihat 3.7) |
| 7 | Microcopy | 🆕 | P1 | Tambah panduan istilah: "Terlewat" bukan "gagal"; "tugas" sebagai satuan |

### 3.6 `DESIGN-WEB.md`

| # | Lokasi | Tanda | Prioritas | Penyesuaian |
| :-: | :--- | :-: | :-: | :--- |
| 1 | §1B Task Edit Modal | 🔁 | P0 | Pangkas v1: **hapus** toolbar rich text, color dot/stabilo, lampiran, pengingat. **Pertahankan** judul, tanggal, checkbox, catatan polos. Pindahkan sisanya ke *Won't (v1)* atau backlog |
| 2 | §1B "gelap/kontras tinggi" dan stabilo | 🔧 | P1 | Bertentangan dengan CONST-01 (monokrom hangat, Ink Black satu-satunya aksen). Selaraskan atau tandai sebagai pengecualian yang diputuskan |
| 3 | Subtasks | 🔁 | P1 | Tumpang tindih dengan breakdown goal. Tunda; breakdown sudah menangani pemecahan tugas |
| 4 | §2 `BrainDumpModal.tsx` | 🔁 | P0 | Bertentangan dengan `PRD §3.6` (tidak ada Chat di web). Ganti quick-add satu baris tanpa AI |
| 5 | §2 `SomedayDrawer.tsx` | 🔁 | P2 | Pertahankan hanya jika riset menunjukkan backlog memperparah P1 (di MoSCoW sudah C6/Could) |
| 6 | Web *empty state* | 🆕 | P0 | Tambah: bila belum ada tugas/goal, arahkan ke mobile untuk mengatur goal (atau putuskan K3) |
| 7 | Label tugas AI | 🆕 | P1 | Tampilkan "dari Goal: …" di `TaskItem.tsx` (read dan edit saja; pembuatan rencana tetap di mobile) |
| 8 | Link `file:///e:/Work-Learn/...` | 🔧 | P2 | Path lokal tidak portabel. Ganti jalur relatif |
| 9 | Persistensi `localStorage` | 🔧 | P1 | `mindmap.md` mencatat web masih mock. Catat jelas di dokumen ini sampai terhubung ke API |

### 3.7 `auth.md`

| # | Lokasi | Tanda | Prioritas | Penyesuaian |
| :-: | :--- | :-: | :-: | :--- |
| 1 | §2 Auto-Login | 🆕 | P0 | Tambah cabang: sesi aktif + `onboarding_completed_at` kosong → **OnboardingScreen**; selain itu → MainScreen |
| 2 | §5A Transisi masuk | 🆕 | P1 | Tambah transisi AuthScreen → OnboardingScreen dan Onboarding → MainScreen |
| 3 | §5B Logout | 🆕 | P2 | "Tab 0 (To-do)" → "Tab 0 (Target)" |
| 4 | §3–4 Tombol Google | 🔧 | P1 | Sketsa dan §4 saling bertentangan (tombol Ink Black vs putih). Putih murni juga melanggar CONST-01 (`#FFFFFF`). Pilih satu dan sesuaikan token |
| 5 | §3–4 Glow gradien | 🔧 | P1 | Radial gradient pastel bertentangan dengan `DESIGN.md §1` dan CONST-01. Putuskan: ubah `auth.md` atau tambah pengecualian eksplisit di `DESIGN.md` |
| 6 | §2 Alur | 🔧 | P2 | Penomoran langkah dobel (dua langkah "4") |

### 3.8 `mindmap.md`

| # | Lokasi | Tanda | Prioritas | Penyesuaian |
| :-: | :--- | :-: | :-: | :--- |
| 1 | Header versi dan §0 | 🆕 | P1 | Update versi/tanggal, hitungan 14/8/8/9. Ganti "To-do" → "Target Harian" |
| 2 | §0 tabel masalah | 🔁 | P1 | Tambah baris **Aktivasi** (hari pertama kosong) dan USP satu kalimat |
| 3 | §1 Mindmap fitur | 🆕 | P1 | Tambah node **M14 Goal Setup & AI Breakdown**. Ganti S4 menjadi dilebur ke M14 |
| 4 | §2 Flowchart pipeline | 🆕 | P1 | Tambah jalur **Goal Planner** (onboarding → draft rencana → persetujuan → `tasks`) |
| 5 | §3B dan §3C | 🆕 | P1 | Judul "To-Do" → Target Harian; teks "daftar To-Do kamu" → "Target Harian kamu" |
| 6 | **Baru §3F** | 🆕 | P1 | Sequence diagram **Goal Setup & Breakdown** |
| 7 | §4 Roadmap | 🆕 | P0 | Tambah **R2b — Aktivasi** di antara R2 dan R3 |
| 8 | §5 Tracking | 🆕 | P1 | Perubahan ini memicu log (lihat langkah akhir di 4.) |

### 3.9 `DEPLOYMENT_GUIDE.md`

| # | Lokasi | Tanda | Prioritas | Penyesuaian |
| :-: | :--- | :-: | :-: | :--- |
| 1 | §2.0 Kapan pindah Tahap 2/3 | 🆕 | P1 | Tambah `POST /goals/{id}/plan` (jika 504 konsisten) sebagai pemicu, bukan hanya `/chat/message` dan cron refleksi |
| 2 | §3.1 komentar struktur web | 🆕 | P2 | "Hybrid Daily/Weekly view" → Target Harian |
| 3 | §5 Daftar cron | 🔧 | P1 | (a) Morning Brief per jam tidak tercantum padahal ada di `technical.md`/`DATABASE.md`. (b) Nama endpoint: panduan memakai `/internal/cron/weekly-reflection`, `technical.md` §5 memakai `/internal/cron/reflection`. Sepakati nama. (c) Jelaskan pembagian tugas scheduler: `pg_cron` Supabase vs cron-job.org |
| 4 | §2.2 / §6 env | 🔧 | P1 | Lihat 3.10 (nama variabel dan `BACKEND_URL`) |

### 3.10 `ENV_GUIDE.md` dan `feedback.md`

| # | File / Lokasi | Tanda | Prioritas | Penyesuaian |
| :-: | :--- | :-: | :-: | :--- |
| 1 | `feedback.md` B2 | 🔧 | P0 | Menyatakan backend dimigrasikan ke **Render.com**. `DEPLOYMENT_GUIDE.md` (keputusan bertahap) dan `technical.md` memakai **Vercel Tahap 1**. Jangan tulis ulang riwayat; tambah catatan "**digantikan oleh `DEPLOYMENT_GUIDE.md`**" pada B2 dan di bagian Status |
| 2 | `feedback.md` | 🆕 | P2 | Tambah entri status untuk keputusan Goal Breakdown dan Target Harian (atau gunakan `track-progress/`) |
| 3 | `ENV_GUIDE.md` §3C vs `DEPLOYMENT_GUIDE.md` §6 | 🔧 | P1 | ENV_GUIDE: Flutter hanya perlu `.env.client` dan tanpa flag. Deployment: memakai `--dart-define=BACKEND_URL`. `BACKEND_URL` tidak ada di contoh `.env.client`. Putuskan satu mekanisme |
| 4 | Nama variabel | 🔧 | P1 | `technical.md §7`: `SUPABASE_URL`, `SUPABASE_KEY`, `JWT_SECRET`. `ENV_GUIDE`/`DEPLOYMENT_GUIDE`: `PUBLIC_SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`. Samakan di semua dokumen |
| 5 | `ENV_GUIDE.md` §5 | 🔧 | P2 | Setup developer baru belum menyebut `.env.client` (ditambahkan di B6 pada §3C dan §4 saja) |

---

## 4. File Baru yang Disarankan

| File | Isi | Prioritas |
| :--- | :--- | :-: |
| `_docs/research/RESEARCH_PLAN.md` | Hipotesis H1–H4 (audit sebelumnya) + **H5** (pengguna mengerjakan tugas hasil breakdown AI sebanding dengan tugas manual) + **H6** (istilah "Target Harian" dipahami dan tidak terasa menekan); kriteria screening; panduan wawancara; keputusan yang akan berubah per hasil | P0 |
| `_docs/USP.md` (atau bagian PRD §1) | Positioning, tiga pilar (proaktif, jujur, belajar), risiko klaim, rencana uji bandingan "asisten umum + kalender vs ALUR" | P1 |
| `track-progress/2026-10-03.md` | Log perubahan hari ini. Wajib menurut kontrak otomasi `AGENTS.md` Rule 5 karena MoSCoW dan spec berubah | P0 |

---

## 5. Keputusan Terbuka (Butuh Pemilik Produk)

| ID | Pertanyaan | Rekomendasi | Konsekuensi jika dipilih lain |
| :-: | :--- | :--- | :--- |
| **K1** | Apakah M14 benar-benar **Must**? | Ya, dengan syarat lolos validasi wizard-of-oz (H5). Argumen: M5 butuh tugas | Jika tidak lolos, kembalikan ke Should dan andalkan jalur brain-dump untuk hari pertama |
| **K2** | Pembuatan goal lewat chat? | Tidak di v1; UI saja | Menambah `GOAL_CAPTURE`, perubahan enum `conversation_logs`, risiko salah deteksi |
| **K3** | Pengguna yang pertama kali masuk lewat **web** | Onboarding hanya di mobile v1; web menampilkan *empty state* yang mengarahkan ke mobile | Jika web harus punya onboarding, tambah form goal minimal di web (melanggar semangat scope `PRD §3.6`) |
| **K4** | Tugas **lepas** (tanpa goal) tidak mendapat chip FORGOT/SKIPPED (aturan `DATABASE §5`, `PRD §3.2`) | Tinjau ulang. Jika Target Harian dianggap komitmen, semua tugas yang terlewat idealnya punya data alasan | Tanpa perubahan, DCDC dan P3 kehilangan sebagian data dari tugas lepas |
| **K5** | Maks. goal aktif berencana dan tugas AI per hari | Usulan awal 3 goal dan 2–3 tugas AI per hari *(hipotesis)* | Terlalu tinggi menciptakan hari penuh dan memperparah P2 |
| **K6** | Nama tab dan layar | "Target" / "Target Harian" setelah copy test (2.2) | Bila hasil uji menunjukkan terasa menekan, pakai "Fokus Hari Ini" |
| **K7** | Rencana dibuat sinkron atau asinkron | Asinkron (`GENERATING → DRAFT`) | Sinkron berisiko 504 pada batas 10 detik Vercel |

---

## 6. Urutan Pengerjaan yang Disarankan

1. **Putuskan K1, K3, K6** (menentukan isi dokumen lain).
2. **PRD**: problem statement, DCDC, glosarium, onboarding, data model, perubahan istilah (baris 1–9, 14, 21).
3. **MOSCOW_FEATURES**: M14, hitungan, urutan rilis R2b (baris 3–5, 9).
4. **DATABASE** dan **technical**: kolom, enum, migrasi `017`, endpoint Goals dan Settings.
5. **DESIGN**, **DESIGN-WEB**, **auth**: komponen baru, pangkas fitur web, selaraskan konflik gaya.
6. **mindmap**, **DEPLOYMENT_GUIDE**, **ENV_GUIDE**, **feedback**: sinkronisasi dan catatan.
7. **Jalankan riset** (H1–H6) paralel dengan langkah 2–5; jangan bangun breakdown AI penuh sebelum H5 punya hasil.
8. **Tulis `track-progress/2026-10-03.md`** dan perbarui `exec/` bila ada checklist terkait.

---

## 7. Checklist Ringkas

- [ ] Putuskan K1–K7
- [ ] PRD: §1, §2, §3.0 (baru), §3.1, §3.2, §3.5, §3.6, §4, §5, §6, §7, §8, §9, Lampiran A
- [ ] MOSCOW: M14, S4 dilebur, 14/8/8/9, R2b, metrik, keputusan, changelog
- [ ] DATABASE: `goals`, `tasks`, `preferences`, migrasi `017`, cron
- [ ] technical: endpoint Goals + Settings, node `goal_planner`, testing
- [ ] DESIGN: nav, komponen baru, radius chip, motion
- [ ] DESIGN-WEB: pangkas v1, hapus BrainDumpModal, *empty state*
- [ ] auth: cabang onboarding, selaraskan gaya
- [ ] mindmap: node M14, flow baru, R2b, versi
- [ ] DEPLOYMENT/ENV/feedback: nama endpoint, nama variabel, catatan Render vs Vercel
- [ ] `RESEARCH_PLAN.md` dan `track-progress/2026-10-03.md`

---

> **Catatan:** `DATABASE.md`, `technical.md`, dan `MOSCOW_FEATURES.md` dibaca langsung dari file. Nomor baris/bagian mengacu pada struktur saat ini; verifikasi ulang bila dokumen sudah berubah sebelum mengedit.
