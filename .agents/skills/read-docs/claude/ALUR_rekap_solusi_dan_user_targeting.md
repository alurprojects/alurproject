# ALUR — Rekap Solusi, Target Market, dan User Targeting

> **Catatan:** Semua angka, segmen, dan ambang keputusan di dokumen ini adalah **hipotesis untuk divalidasi**, bukan fakta. Tidak ada data riset ALUR yang tersedia saat dokumen ini disusun.

**Sumber:** audit project brief + dokumen ALUR (`PRD.md`, `mindmap.md`, `DESIGN-WEB.md`, `DEPLOYMENT_GUIDE.md`, `feedback.md`).

---

## Bagian 1 — Solusi per Masalah

### 1.1 Masalah: "Kenyamanan" tidak terukur dan rantai logika tidak bisa diuji

**Solusi:** gunakan rantai **Masalah → Insight → Fitur → Outcome**, dan beri tiap fitur satu metrik.

| Masalah | Insight (hipotesis) | Fitur | Outcome terukur |
| :--- | :--- | :--- | :--- |
| P1 Bingung prioritas pagi | Overwhelm datang dari terlalu banyak pilihan, bukan terlalu banyak tugas | Morning Brief Top 3 + Capacity Warning | Waktu dari buka app ke tugas pertama dimulai turun; % Top 3 yang diselesaikan |
| P2 To-do jarang tuntas | Pengguna menjadwalkan melebihi kapasitas dan tidak pernah dikonfrontasi | Nightly MISSED + reschedule 1-tap | Rasio tugas MISSED per minggu turun; reschedule acceptance rate |
| P3 Tidak paham pola sendiri | Orang tidak punya cermin atas perilakunya | Insight Mingguan naratif | % insight dibuka; % pengguna yang mengubah perilaku setelahnya |

**Aturan keputusan:** fitur yang tidak bisa ditunjuk ke satu baris tabel ini ditunda atau dibuang.

### 1.2 Masalah: Fitur yang tidak terhubung ke masalah

- **Calendar tab:** turunkan dari R1 ke setelah validasi. Tetap *Should*, dibangun hanya jika riset menunjukkan pengguna butuh melihat beban dalam bentuk waktu. Jika ya, hubungkan ke P1 sebagai visual kapasitas.
- **Web (`DESIGN-WEB.md`):** potong untuk v1. Toolbar rich text, color highlighter, lampiran, dan pengingat masuk *Won't (v1)*. Pertahankan judul, tanggal, checkbox, dan satu kolom catatan polos. Selaras dengan prinsip *Invisible Complexity*.
- **BrainDumpModal vs PRD §3.6:** satu dokumen harus menang. Saran: PRD menang, ganti modal dengan quick-add satu baris tanpa AI. Brain-dump penuh tetap di mobile.
- **Someday Drawer:** pertahankan hanya jika riset menunjukkan backlog memperparah kebingungan P1. Jika tidak, tunda.
- **P1–P3 dipindah ke PRD §1** sebagai sumber kebenaran, bukan hanya di `mindmap.md`.

### 1.3 Masalah: Behavior asumtif, DCDC kabur, belum ada problem statement

**Draft problem statement:**

> "Pekerja muda dan freelancer yang memegang banyak komitmen tak terstruktur sering memulai hari tanpa tahu apa yang layak dikerjakan lebih dulu, menjadwalkan melebihi kapasitas, lalu tidak punya cara melihat pola itu. Hasilnya: kewalahan, tugas menumpuk, dan rasa bersalah."

**Tabel bukti perilaku** (diisi dari riset):

| Perilaku | Status | Sumber yang dibutuhkan |
| :--- | :--- | :--- |
| Menunda memilih tugas pertama | Asumsi | Wawancara, observasi |
| Menjadwalkan lebih dari kapasitas | Asumsi | Data jadwal 1–2 minggu dari partisipan |
| Tidak tahu alasan tugas terlewat | Asumsi | Wawancara |

**Definisi operasional DCDC (usulan):** jumlah keputusan terkait rencana yang diambil pengguna secara aktif per hari, yaitu memilih/mengubah Top 3, menerima atau menolak saran reschedule, dan menandai FORGOT/SKIPPED. Persetujuan otomatis tidak dihitung.

- **Baseline:** ukur 2 minggu pertama beta sebelum optimasi.
- **Guardrail metric:** opt-out dari saran, tingkat tap asal-asalan (jawaban FORGOT/SKIPPED dalam < 1 detik), dan retensi D7/D30. Mencegah DCDC naik hanya karena aplikasi memaksa lebih banyak tap.

### 1.4 Masalah: Riset belum spesifik

**Rencana riset minimum (±2–3 minggu):**

| Hipotesis berisiko | Metode | Kriteria lanjut (usulan) |
| :--- | :--- | :--- |
| H1: Pengguna mau diragukan komitmennya oleh AI | Wawancara + uji konsep copy Capacity Warning (HONEST vs GENTLE) | ≥ 5 dari 8 menilai berguna, bukan menghakimi |
| H2: Top 3 lebih membantu daripada daftar penuh | Wizard-of-Oz: kirim "Morning Brief" manual via WhatsApp selama 5 hari ke 5–8 orang | Mayoritas membuka brief dan mengerjakan ≥ 1 dari Top 3 |
| H3: Reschedule 1-tap diterima | Prototipe Figma | Acceptance rate di atas ambang yang disepakati |
| H4: Pengguna menjawab FORGOT/SKIPPED dengan jujur | Wawancara lanjutan | Alasan jawaban konsisten dengan perilaku |

Tetapkan di awal keputusan apa yang berubah tergantung hasil. Contoh: jika H1 gagal, tone HONEST jadi opt-in dan GENTLE jadi default.

### 1.5 Asumsi & risiko yang belum tercatat

| Risiko | Mitigasi |
| :--- | :--- |
| **Cold start:** AI belum tahu pola pengguna baru, P3 kosong di minggu pertama | Onboarding menanyakan kapasitas harian; Morning Brief jadi "aha moment" di hari pertama |
| **Privasi curhat** di `conversation_logs` | Kontrol data yang jelas (sudah ada di Profile), enkripsi, transparansi pemakaian data |
| **Latency AI** vs batas 10 detik Vercel | Pantau 504, siapkan jalur Tahap 2/3 (sudah ada di deployment guide) |
| **Inkonsistensi dokumen:** `feedback.md` menyebut backend migrasi ke Render, sedangkan `DEPLOYMENT_GUIDE.md` masih Vercel | Tentukan satu keputusan resmi dan sinkronkan semua dokumen |

---

## Bagian 2 — Target Market dan User

### 2.1 Tiga lapis yang dipisahkan

| Lapis | Pertanyaan | Usulan untuk ALUR |
| :--- | :--- | :--- |
| **Market** | Siapa yang bisa dilayani? | Orang dewasa muda pengguna smartphone yang mengelola komitmen sendiri, berbahasa Indonesia |
| **Segmen** | Siapa yang paling cocok? | 3 kandidat di bawah |
| **First user (beachhead)** | Siapa yang dilayani pertama? | Satu segmen dari kandidat itu |

### 2.2 Kandidat segmen (hipotesis)

| Segmen | Situasi | Mengapa cocok | Risiko |
| :--- | :--- | :--- | :--- |
| **A. Pekerja awal karier (22–30)** | Kerja + side project + urusan pribadi, pagi sering kewalahan | Pemakaian harian tinggi, web desktop berguna | Sudah terikat alat kantor |
| **B. Mahasiswa tingkat akhir** | Skripsi + organisasi + kerja paruh waktu | Mudah direkrut untuk riset, deadline panjang yang mudah ditunda | Daya beli rendah, pola tidak stabil |
| **C. Freelancer/solopreneur** | Tanpa atasan, kapasitas = penghasilan | Konsekuensi over-commit nyata, "jujur soal kapasitas" paling relevan | Pasar lebih kecil, jadwal tidak teratur |

**Rekomendasi:** mulai dari **A atau C** sebagai beachhead, lalu uji B sebagai segmen kedua. Klaim *honest capacity* paling bernilai bagi orang yang konsekuensi over-commit-nya nyata. Putuskan setelah 6–8 wawancara.

### 2.3 Job-to-be-done (draft)

> "Ketika pagi dan banyak hal berebut perhatianku, aku ingin tahu satu-dua hal yang benar-benar layak dikerjakan hari ini, supaya energiku tidak habis untuk memilih dan menyesal."

### 2.4 Siapa BUKAN user prioritas

- Orang yang butuh kolaborasi tim (ALUR bersifat personal).
- Pengguna GTD/Notion tingkat lanjut yang butuh kontrol penuh.
- Orang yang mencari motivasi dan dukungan tanpa syarat. Nada HONEST bisa terasa mengganggu, jadi ini perlu masuk kriteria screening riset.

### 2.5 Kompetitor sebenarnya (petakan dalam riset)

Catatan HP, chat ke diri sendiri di WhatsApp, Google Calendar/Keep, Todoist/TickTick, Tweek, dan "tidak pakai apa-apa".

### 2.6 Konteks lokal

Bahasa Indonesia santai, kebiasaan chat-first (WhatsApp), dan dominasi Android. Ini mendukung mobile-first dan Chat Room sebagai pintu masuk, jadi masukkan ke profil user.

### 2.7 Ukuran pasar

Hitung bertahap (TAM → SAM → SOM) dari data populasi dan penetrasi smartphone yang bisa diverifikasi. Jangan memakai satu angka besar tanpa sumber.

---

## Bagian 3 — Siapa Sebenarnya User ALUR? (Pengangguran vs Pekerja)

**Jawaban singkat:** bukan pengangguran, dan juga bukan "pekerja dengan jadwal tetap". Yang menentukan user bukan status kerja, tetapi **struktur waktu**.

Masalah yang diselesaikan ALUR adalah *banyak komitmen yang berebut kapasitas terbatas, tanpa ada yang memaksa urutannya*. Pertanyaan screening yang tepat: **seberapa besar bagian hari orang ini yang harus ia atur sendiri?**

### 3.1 Kecocokan berdasarkan kondisi

| Kondisi | Waktu terstruktur dari luar? | Cocok untuk ALUR? |
| :--- | :--- | :--- |
| Pekerja shift / jam kantor kaku, tanpa kegiatan lain | Hampir seluruhnya | Rendah. Jadwal sudah memutuskan untuknya |
| Pekerja kantoran + side project + urusan pribadi | Sebagian (jam kerja tetap) | **Tinggi** pada porsi di luar jam tetap, dan pada urutan tugas di dalam pekerjaan itu sendiri |
| Freelancer / solopreneur | Hampir tidak ada | **Tinggi**, semua harus diatur sendiri |
| Mahasiswa tingkat akhir (skripsi, organisasi, kerja paruh waktu) | Sedikit | **Tinggi** |
| Pengangguran / pencari kerja | Hampir tidak ada | Rendah sampai sedang |

### 3.2 Pekerja yang "sudah punya template waktu"

Jam kerja tetap menyelesaikan masalah *kapan*, tetapi tidak menyelesaikan *apa yang dikerjakan lebih dulu*. Di dalam jam 09.00–17.00, orang masih menghadapi banyak tugas dan bingung memilih. Di luar jam itu, ada hal lain yang tidak punya template sama sekali. Jadi pekerja tetap relevan, selama ia punya **komitmen yang tidak terstruktur**.

**Konsekuensi desain:** `daily_capacity_hours` saat ini hanya satu angka. Untuk pekerja kantoran, kapasitas sebenarnya adalah *jam bebas dikurangi blok tetap*. Onboarding perlu menanyakan jam kerja/kuliah yang tidak bisa diganggu, supaya Capacity Warning tidak salah hitung. Tanpa ini, "jujur soal kapasitas" justru jadi tidak jujur.

### 3.3 Pengangguran: bukan target utama

1. **Klaim inti (kejujuran kapasitas) butuh komitmen yang bersaing.** Orang dengan sedikit komitmen jarang overload, sehingga nilai produknya tipis.
2. **Daya beli dan kondisi emosional.** Nada HONEST yang meragukan komitmen bisa menyakitkan bagi orang yang sedang rentan secara finansial atau mental.
3. **Mereka bukan "tanpa komitmen".** Pencari kerja sering punya banyak lamaran, belajar skill, dan wawancara. Namun itu use case berbeda (job-hunt tracker) dan akan menarik ALUR keluar dari positioning.

Mereka boleh memakai ALUR, tetapi jangan dijadikan dasar keputusan desain.

### 3.4 Rekomendasi beachhead

**Orang dewasa muda dengan otonomi atas waktunya dan lebih dari satu sumber komitmen.** Dalam praktik: freelancer, atau pekerja awal karier yang punya side project. Mahasiswa tingkat akhir menjadi segmen kedua yang mudah direkrut untuk riset.

### 3.5 Kriteria screening riset (usulan)

- Punya minimal 3 komitmen berbeda yang bersaing (kerja, proyek, urusan pribadi/keluarga).
- Sedikitnya sebagian harinya diatur sendiri.
- Pernah merasa kewalahan memilih prioritas, dan **sudah pernah mencoba** alat lain (catatan HP, to-do app). Ini membedakan orang yang merasakan masalah dari yang hanya mengaku.
- Bersedia menerima umpan balik jujur.

### 3.6 Cara memastikan

Wawancara 6–8 orang dari 2–3 kondisi di tabel 3.1, lalu lihat siapa yang masalahnya paling nyata dan paling sering muncul. Jika ternyata pekerja jam kaku merasakan masalah P1 sama kuatnya, segmen itu layak dipertimbangkan. Data wawancara yang memutuskan, bukan asumsi.

---

## Ringkasan Prioritas Tindakan

1. Tulis problem statement di PRD §1 beserta bukti perilaku dan sumbernya.
2. Ganti "kenyamanan" dengan outcome terukur; definisikan DCDC dan baseline-nya.
3. Terapkan uji traceability pada tiap fitur, mulai dari Calendar dan fitur Web yang berlebih.
4. Pertajam target dari umur ke situasi dan job-to-be-done (struktur waktu).
5. Tambahkan pertanyaan jam tetap di onboarding agar perhitungan kapasitas jujur.
6. Jalankan riset kecil untuk menguji H1–H4, mulai dari klaim "honest capacity".
7. Sinkronkan keputusan deployment (Vercel vs Render) di seluruh dokumen.
