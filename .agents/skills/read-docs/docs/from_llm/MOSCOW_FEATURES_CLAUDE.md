# ALUR — Penetapan Fitur dengan Metode MoSCoW

> **Peran:** Product Designer
> **Cakupan:** Aplikasi Mobile (Flutter) + Web (Next.js) dengan asisten AI (FastAPI + LangGraph)
> **Sumber:** `PRD.md`, `technical.md`, `DESIGN.md`, `DESIGN-WEB.md`, `mindmap.md`, `auth.md`, `DATABASE.md`

---

## 1. Masalah Pengguna & Prinsip Prioritas

| # | Masalah Pengguna | Akar Masalah | Jawaban Produk |
| :-: | :--- | :--- | :--- |
| P1 | Bingung menentukan prioritas kerja tiap pagi | Terlalu banyak task, tidak ada yang memilah mana yang penting dan muat hari ini | **Morning Priority Brief** + cek kapasitas |
| P2 | To-do harian jarang tuntas 100% | Perencanaan tidak realistis dan task yang tertinggal menumpuk | **Capacity check** + **reschedule otomatis (dengan persetujuan)** |
| P3 | Tidak tahu pola kerja sendiri | Tidak ada umpan balik yang jujur | **Insight produktivitas** berbasis data task + chat |

**Filter prioritas.** Sebuah fitur masuk *Must Have* hanya jika tanpa fitur itu **P1 atau P2 tidak terselesaikan**, atau produk tidak bisa berjalan (auth, data, keamanan).

---

## 2. Ringkasan MoSCoW

| Kategori | Jumlah | Peran dalam Produk |
| :--- | :-: | :--- |
| 🟥 **Must Have** | 12 | Inti nilai produk, tanpa ini rilis tidak layak |
| 🟧 **Should Have** | 9 | Penting, memperkuat nilai inti, bisa menyusul tepat setelah rilis awal |
| 🟨 **Could Have** | 8 | Nilai tambah, dikerjakan jika waktu dan sumber daya cukup |
| ⬜ **Won't Have (kali ini)** | 9 | Sengaja tidak dibangun di siklus ini |

---

## 3. 🟥 MUST HAVE — Wajib Ada

| ID | Fitur | Platform | Menjawab | Alasan Wajib | Fase* |
| :-: | :--- | :-: | :-: | :--- | :-: |
| **M1** | **Login Google OAuth** (Supabase Auth, satu metode) | 📱🌐 | Fondasi | Tanpa akun, tidak ada data per user. Satu metode saja agar sign-up tanpa hambatan. | 1 |
| **M2** | **Hybrid To-do: Daily Focus + Weekly Overview** | 📱🌐 | P1, P2 | Ruang eksekusi utama. Daily Focus mengurangi kebingungan, Weekly memberi gambaran beban. | 1 |
| **M3** | **Task CRUD manual** (tambah cepat, centang, edit, hapus) + **estimasi durasi** | 📱🌐 | P2 | Estimasi durasi adalah bahan hitung kapasitas. Tanpa estimasi, "realistis" tidak bisa dihitung. | 1 |
| **M4** | **Chat Room: Brain-dump → Task Capture** (Extractor Agent) | 📱 | P1 | Menurunkan friksi input. Satu kalimat berantakan langsung menjadi task terstruktur. | 2 |
| **M5** | **Morning Priority Brief**: AI menyusun **Top 3 prioritas hari ini** dan alasannya | 📱🌐 | **P1** | Jawaban langsung untuk masalah "bingung tiap pagi". Ditampilkan sebagai kartu di puncak Daily Focus. *(Fitur baru, belum ada di PRD.)* | 2 |
| **M6** | **Cek Kapasitas Harian** (total estimasi vs `daily_capacity_hours`) + peringatan overload | 📱🌐 | P1, P2 | Akar dari to-do yang tak tuntas adalah rencana yang melebihi kapasitas. Scheduler Agent menandai lebih awal. | 2 |
| **M7** | **Nightly Status Check**: task PENDING yang lewat menjadi MISSED (per timezone user) | ⚙️ | P2 | Pemicu seluruh alur reschedule, tanpa ini tidak ada data "tertunda". | 3 |
| **M8** | **Saran Reschedule Otomatis (AI mengusulkan, user setuju 1 tap)** via `task_suggestions` | 📱🌐 | **P2** | Inti fitur "mendelegasikan tugas tertunda ke hari lain". AI memilih hari yang muat kapasitasnya. | 3 |
| **M9** | **Follow-up FORGOT / SKIPPED** (chip pada task MISSED) | 📱🌐 | P2, P3 | Membedakan lupa dan sengaja dilewati, sehingga reschedule dan insight tidak berasumsi "gagal". | 3 |
| **M10** | **Insight Produktivitas Mingguan** (Reflection Agent → `ai_insights`) dalam bentuk narasi singkat | 📱🌐 | **P3** | Inti "analisis produktivitas mendalam": pola task MISSED + riwayat chat, disajikan sebagai kalimat, bukan tumpukan grafik. | 3 |
| **M11** | **Orchestrator Gatekeeper**: aturan kapan brief, saran, dan insight boleh muncul (default diam) | ⚙️ | Semua | Mencegah AI menjadi noise. Tanpa ini M5, M8, dan M10 justru membebani. | 2–3 |
| **M12** | **Fondasi Data & Keamanan**: skema Supabase, RLS, endpoint cron dengan `X-Cron-Secret`, CORS eksplisit | ⚙️ | Fondasi | Data pribadi (task dan curhat) wajib terlindungi sebelum rilis. | 1–3 |

\* Fase mengacu pada PRD Section 7. 📱 = Mobile, 🌐 = Web, ⚙️ = Backend.

### Definisi "selesai" fitur kunci

- **M5 Morning Brief** dianggap selesai jika: (a) tampil otomatis saat app pertama dibuka setiap hari, (b) berisi maksimal 3 task dengan satu kalimat alasan masing-masing, (c) total estimasi Top 3 tidak melebihi kapasitas harian, (d) bisa diabaikan tanpa konsekuensi.
- **M8 Reschedule** dianggap selesai jika: (a) AI tidak pernah memindahkan task tanpa persetujuan, (b) hari tujuan yang disarankan selalu masih punya sisa kapasitas, (c) user bisa menerima atau menolak per task, (d) alasan penolakan disimpan untuk pembelajaran.

---

## 4. 🟧 SHOULD HAVE — Sangat Penting, Tidak Menghalangi Rilis Awal

| ID | Fitur | Platform | Alasan Prioritas Kedua |
| :-: | :--- | :-: | :--- |
| **S1** | **Companion Agent 2-Tone** (HONEST default, GENTLE saat terdeteksi burnout) | 📱 | Meningkatkan kepercayaan dan retensi, tetapi alur inti tetap jalan dengan satu nada netral. |
| **S2** | **Batch Reschedule 1-tap** ("Geser semua sisa hari ini ke besok") saat mode GENTLE | 📱🌐 | Mempercepat M8 saat user kewalahan. M8 per task sudah cukup untuk MVP. |
| **S3** | **Calendar Tab Time-block** (read-only, 06:00–22:00, section Unscheduled) | 📱🌐 | Membantu memvisualisasikan beban waktu, tetapi bukan pengganti to-do. |
| **S4** | **Goals** (hubungkan task ke goal, tampil di Profile) | 📱 | Membuat prioritas di M5 lebih bermakna (task terkait goal diberi bobot). |
| **S5** | **Task Berulang + Weekly Recurrence Generator** | 📱🌐 | Kebutuhan rutinitas, tetapi bisa ditambah manual di awal. |
| **S6** | **Push Notification** (Morning Brief, saran reschedule) | 📱 | Menghidupkan kebiasaan pagi, meski user tetap bisa membuka app sendiri. |
| **S7** | **Deteksi Pola** (jam paling produktif, hari terberat, jenis task yang sering MISSED) pada insight | 📱🌐 | Memperdalam M10 dari sekadar rangkuman menjadi analisis pola. |
| **S8** | **Kontrol Retensi Chat** (banner pending-deletion, unduh backup, simpan selamanya, hapus riwayat) | 📱 | Kepatuhan privasi. Wajib sebelum rilis publik luas, tetapi bukan alur nilai inti. |
| **S9** | **Web Parity** untuk To-do dan Calendar (termasuk Task Edit Modal dan tampilan mingguan penuh) | 🌐 | Web berperan sebagai layar perencanaan besar. Sesuai keputusan PRD, tanpa Chat dan Profile. |

---

## 5. 🟨 COULD HAVE — Nilai Tambah

| ID | Fitur | Platform | Catatan |
| :-: | :--- | :-: | :--- |
| **C1** | Integrasi **Google Calendar** (read-only) untuk membaca waktu sibuk saat menghitung kapasitas | 📱🌐 | PRD menempatkannya di Tahap B. Meningkatkan akurasi M6 dan M8. |
| **C2** | **Voice-to-text** untuk brain-dump | 📱 | Mempercepat capture, namun teks sudah memenuhi kebutuhan. |
| **C3** | **Someday Drawer** (backlog tugas belum terjadwal) | 🌐 | Menampung ide tanpa mengotori jadwal. |
| **C4** | **Brain Dump Modal** multi-tugas di web (tanpa AI chat) | 🌐 | Alternatif ringan bagi user web. |
| **C5** | **Detail task kaya**: subtask, catatan, warna stabilo, lampiran | 📱🌐 | Kenyamanan, bukan pemecah masalah inti. |
| **C6** | **Dark mode** | 📱🌐 | Menambah kenyamanan. Perlu penyesuaian token palet hangat. |
| **C7** | **Tuning kepribadian adaptif** (nada belajar dari respons user) | 📱 | Butuh cukup data pemakaian terlebih dahulu. |
| **C8** | **Ekspor / bagikan ringkasan mingguan** (PDF atau gambar) | 📱🌐 | Berguna untuk refleksi pribadi. |

---

## 6. ⬜ WON'T HAVE (Kali Ini) — Sengaja Ditunda atau Dikeluarkan

| ID | Fitur | Alasan |
| :-: | :--- | :--- |
| **W1** | **Reschedule tanpa persetujuan user** | Bertentangan dengan Non-Goals PRD dan merusak rasa kendali. Kejujuran AI hanya dipercaya bila user tetap pemegang keputusan. |
| **W2** | **Dashboard dan grafik analitik penuh** | Bertentangan dengan prinsip *Invisible Complexity*. Analisis disampaikan lewat narasi (M10). |
| **W3** | **Gamifikasi** (streak, leaderboard, level) | Non-Goal PRD, mendorong tekanan, bukan realisme. |
| **W4** | **Harada / 8-Pilar** | Non-Goal PRD, di luar masalah pengguna. |
| **W5** | **Personalisasi gaya belajar** (`learning_style`) | Non-Goal PRD, tidak terkait manajemen waktu. |
| **W6** | **Chat Room dan Profile di Web** | Keputusan sadar PRD Section 3.6, menunggu mobile stabil. |
| **W7** | **Kolaborasi tim / berbagi task** | Target v1 adalah individu. |
| **W8** | **Integrasi pihak ketiga lain** (Notion, Todoist, Slack) dan **write** ke Google Calendar | Menambah permukaan kerja dan risiko sebelum inti terbukti. |
| **W9** | **Login Email + Password** | Sengaja dihapus untuk menyederhanakan MVP (`auth.md`). |

---

## 7. Peta Fitur terhadap Masalah

```text
P1  Bingung prioritas tiap pagi ──► M5 Morning Brief ── M6 Cek Kapasitas ── M4 Brain-dump
                                     └─ diperkuat: S4 Goals, S6 Push, C1 Google Calendar

P2  To-do jarang tuntas ─────────► M6 Cek Kapasitas ── M7 Nightly MISSED ── M8 Reschedule
                                     └─ diperkuat: M9 FORGOT/SKIPPED, S2 Batch Reschedule

P3  Tidak paham pola sendiri ────► M10 Insight Mingguan ── M9 FORGOT/SKIPPED
                                     └─ diperkuat: S7 Deteksi Pola, S1 Nada GENTLE
```

---

## 8. Urutan Rilis yang Disarankan

| Rilis | Isi | Hasil bagi Pengguna |
| :--- | :--- | :--- |
| **R1 — Fondasi** | M1, M2, M3, M12 | To-do rapi di mobile dan web. |
| **R2 — Prioritas Pagi** | M4, M5, M6, M11 + S1 | Pagi tidak lagi bingung: ada Top 3 dan peringatan overload. |
| **R3 — Reschedule & Insight** | M7, M8, M9, M10 + S2, S7 | Task tertunda dipindah otomatis dengan persetujuan, plus pola mingguan. |
| **R4 — Penyempurnaan** | S3, S4, S5, S6, S8, S9 | Kalender, goals, rutinitas, notifikasi, privasi, web penuh. |
| **Backlog** | Semua *Could Have* | Berdasarkan umpan balik pengguna. |

---

## 9. Metrik Keberhasilan

| Masalah | Metrik | Target Awal |
| :--- | :--- | :--- |
| P1 | % user yang membuka Morning Brief dan mengerjakan ≥1 dari Top 3 | ≥ 60% hari aktif |
| P2 | Completion rate harian (task selesai ÷ task terjadwal) | Naik ≥ 20% dibanding 2 minggu pertama |
| P2 | Acceptance rate saran reschedule | ≥ 50% |
| P3 | % user yang membaca insight mingguan | ≥ 40% |
| Semua | **DCDC** (Daily Conscious Decision Count), North Star di PRD | Tren naik mingguan |

---

## 10. Keputusan Desain yang Perlu Dikonfirmasi

1. **"Otomatis" vs "Non-Goal auto-reschedule".** Brief meminta reschedule otomatis, sedangkan PRD melarang reschedule tanpa persetujuan. Dokumen ini menyelaraskannya menjadi *otomatis diusulkan, dieksekusi setelah 1 tap setuju*. Jika ingin benar-benar otomatis, PRD Section 8 harus direvisi.
2. **"Analisis mendalam" vs "Invisible Complexity".** Kedalaman analisis ditaruh di backend (pola dari task + chat), sementara tampilannya berupa narasi singkat. Dashboard penuh dikeluarkan (W2).
3. **Morning Brief belum ada di PRD.** Fitur M5 perlu ditambahkan ke PRD Section 3.2 (Daily Focus), `technical.md` (endpoint brief), dan `DATABASE.md` bila hasil brief ingin disimpan.
4. **Batas waktu backend.** M5, M8, dan M10 memanggil LLM. Dengan batas 10 detik di Vercel Hobby, hasil brief dan insight sebaiknya **dihitung sebelumnya lewat cron** lalu disajikan dari database, bukan dihitung saat user membuka app.
5. **Dokumen belum sinkron soal hosting.** `feedback.md` menyebut backend pindah ke Render.com, sedangkan `DEPLOYMENT_GUIDE.md` masih memakai Vercel (Tahap 1). Perlu diputuskan mana yang berlaku.
