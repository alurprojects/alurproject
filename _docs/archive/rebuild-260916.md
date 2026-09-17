# rebuild-260916.md

**Tujuan**: Kumpulan instruksi atomik untuk mengeksekusi revisi `PRD.md`, `DESIGN.md`, `DATABASE.md`, `technical.md` berdasarkan keputusan di `brainstorm-26-16-9.md` Section 8, plus 1 klarifikasi baru dari sesi ini.

**Cara pakai**: Tiap TASK berisi `File`, `Action` (ADD/MODIFY/REMOVE/KEEP), `Location`, `Change`. Eksekusi berurutan per file. Task berstatus `[BLOCKED]` jangan dieksekusi dulu — lihat Section "Pertanyaan Menahan Eksekusi" di bagian bawah.

---

## Governing Constraints (Berlaku ke Semua Task, Jangan Dilanggar)

- CONST-01: Tab **To-do list** memakai desain checklist yang SUDAH ADA di `DESIGN.md` Section 3-4 (day header, day strip, task row, checkbox) — **tidak boleh diubah** oleh task apa pun di file ini.
- CONST-02: Struktur akhir adalah **3 tab**: To-do list, Calendar, Profile. Bukan 5, bukan 4 (kecuali Pertanyaan Menahan Eksekusi di bawah dijawab "4 tab").
- CONST-03: Goals **tidak** punya tab sendiri — jadi section di dalam Profile.
- CONST-04: Google Calendar dibangun bertahap: Tahap A (internal view) → Tahap B (GCal read-only) → Tahap C (GCal dua-arah, ditunda tanpa batas waktu sampai A & B stabil).
- CONST-05: `learning_style` dan turunannya (motivation_drivers, challenge_response, dst) **tidak dikumpulkan** dalam bentuk apa pun (eksplisit maupun implisit) untuk saat ini.
- CONST-06: Data onboarding yang tetap dikumpulkan: `timezone`, `daily_capacity_hours`, jam produktif (untuk energy-matching Level 3).
- CONST-07: Palet warna & tipografi mengikuti `DESIGN.md` Section 2-3 yang sudah ada — semua komponen baru TIDAK boleh menambah warna baru.

---

## TASK — PRD.md

**TASK-P01**
- File: `PRD.md`
- Action: MODIFY
- Location: Section "2. Perubahan Fundamental dari v1", baris tabel "Jumlah tab mobile"
- Change: Ganti nilai kolom "v2 (baru)" dari `1 layar utama untuk MVP + Settings minimal` menjadi `3 tab: To-do list (checklist, desain tidak berubah), Calendar (breakdown harian + Google Calendar), Profile (settings + Goals)`

**TASK-P02** `[RESOLVED — Opsi A dipilih]`
- File: `PRD.md`
- Action: ADD
- Location: Setelah Section 3 (UI — Satu Layar, Bukan Lima), ganti judul section 3 dari "Satu Layar, Bukan Lima" jadi "To-do List (Checklist, Tidak Berubah)" agar tidak menyesatkan pembaca yang tahu sekarang ada 3 tab
- Change: Tambah subsection baru "3.x Calendar Tab — Breakdown Harian & Timebox":
  ```
  Calendar tab adalah rumah untuk breakdown harian + timebox (bukan To-do list — CONST-01).
  Isi:
  - Habit hari ini (task dengan recurrence_rule terisi)
  - Task dari goals yang assigned_date = hari ini
  - Event Google Calendar (Tahap B, read-only, lihat CONST-04)
  Disusun sebagai time-block vertikal (bukan flat list), diurutkan jam.
  Task/habit tanpa estimated_minutes/waktu spesifik dikelompokkan di
  bagian "Unscheduled" di atas/bawah blok waktu, tidak dipaksa masuk slot jam.
  Ini TIDAK menggantikan To-do list — user tetap centang task di tab To-do list;
  Calendar cuma representasi ulang data yang sama dalam bentuk waktu.
  Task di Calendar bersifat READ-ONLY untuk status (tidak ada checkbox di sini) —
  mencegah 2 tempat sumber kebenaran untuk aksi centang, tap task di Calendar
  cukup navigasi balik ke To-do list pada hari yang sesuai.
  ```

**TASK-P03**
- File: `PRD.md`
- Action: MODIFY
- Location: Section "6. Non-Goals"
- Change: Hapus baris "Tidak ada multi-tab navigation di Fase 1" (sudah tidak berlaku). Tambah baris baru: "`learning_style`/personalisasi cara-belajar tidak dikumpulkan (CONST-05)"

**TASK-P04**
- File: `PRD.md`
- Action: ADD
- Location: Section "7. MVP Scope" atau roadmap fase
- Change: Tambah baris fase Google Calendar sesuai CONST-04 (Tahap A/B/C), tempatkan Tahap A di Fase yang sama dengan Calendar tab dibangun, Tahap B di Fase setelahnya, Tahap C ditandai "belum dijadwalkan"

---

## TASK — DESIGN.md

**TASK-D01**
- File: `DESIGN.md`
- Action: KEEP
- Location: Section 3 (Typography), Section 4 subsections "Day Header", "Day Strip", "Task Row", "Follow-up/Reschedule Chip"
- Change: TIDAK ADA perubahan (CONST-01). Task ini eksis cuma sebagai penanda eksplisit "jangan sentuh" untuk AI eksekutor.

**TASK-D02** `[RESOLVED — Opsi A dipilih]`
- File: `DESIGN.md`
- Action: ADD
- Location: Setelah Section 4 (Component Stylings)
- Change: Tambah subsection "Calendar Tab Components":
  ```
  ### Timeline / Time-Block View
  - Layout: vertical scroll, jam sebagai sumbu (mis. 06:00–22:00), garis Hairline Gray
    tiap jam, label jam di kiri dalam Warm Gray.
  - Task/habit block: solid Paper Gray background, 8px rounded corners, judul task
    (Charcoal), durasi ditunjukkan lewat tinggi block relatif terhadap skala jam.
    TIDAK ada checkbox di sini (read-only, lihat PRD.md TASK-P02).
  - Event Google Calendar: visual dibedakan tipis — border-dashed 1px Hairline Gray,
    background transparan (bukan Paper Gray solid), tanpa aksi tap selain "lihat detail".
    Tidak memakai warna baru di luar palet (CONST-07).
  - Unscheduled section: strip di atas timeline (sebelum jam 06:00), berisi task
    tanpa waktu spesifik — style sama seperti Day Strip collapsed di To-do list,
    supaya konsisten secara visual dengan tab lain.
  - Navigasi hari: swipe kiri/kanan atau date-picker minimal di header, tidak perlu
    month-grid penuh di v1 — cukup 1 hari dalam fokus, mirip pola To-do list yang
    sudah auto-expand 1 hari aktif.
  ```

**TASK-D03**
- File: `DESIGN.md`
- Action: ADD
- Location: Setelah Section 4
- Change: Tambah subsection "Profile Tab — Goals Section" — list goal pakai pola visual task row yang sudah ada (title + status label + deadline), tanpa komponen baru

**TASK-D04**
- File: `DESIGN.md`
- Action: MODIFY
- Location: Section 4 "Bottom Navigation"
- Change: Update dari deskripsi generik "3-4 icon-only items" menjadi eksplisit 3 ikon: checklist (To-do list), calendar (Calendar), user/profile (Profile) — urutan kiri ke kanan sesuai urutan ini

---

## TASK — DATABASE.md

**TASK-DB01**
- File: `DATABASE.md`
- Action: ADD
- Location: Section 4 (Tabel `goals`), tambah kolom
- Change: Tambah kolom `priority SMALLINT` (nullable, 1=tertinggi) ATAU hitung urgency dari `deadline` di application layer — pilih salah satu, dokumentasikan alasan di komentar SQL. Untuk Smart Breakdown Level 2 (lihat `brainstorm-26-16-9.md` Section 8.3)

**TASK-DB02**
- File: `DATABASE.md`
- Action: ADD
- Location: Tabel baru, setelah Section 7 (`ai_insights`)
- Change: Tambah definisi tabel `google_calendar_connections` — kolom minimal: `id, user_id, access_token, refresh_token, token_expiry, gcal_calendar_id, sync_enabled BOOLEAN DEFAULT FALSE, created_at`. Tandai di migrasi Section 11 sebagai **Tahap B** (bukan Fase 1) — tabel independen baru, aman dibuat belakangan (ikuti prinsip yang sudah diperbaiki sebelumnya: bukan seperti kolom di tabel `tasks` yang perlu disiapkan lebih awal)

**TASK-DB03**
- File: `DATABASE.md`
- Action: NONE (eksplisit dilarang)
- Location: —
- Change: JANGAN tambah kolom/tabel apa pun untuk `learning_style` atau personalisasi sejenis (CONST-05)

---

## TASK — technical.md

**TASK-T01**
- File: `technical.md`
- Action: ADD
- Location: Section 1 (Stack Overview)
- Change: Tambah baris "Google Calendar API — OAuth + read events (Tahap B), scope `calendar.readonly`"

**TASK-T02**
- File: `technical.md`
- Action: ADD
- Location: Section 4 (API Contract)
- Change: Tambah endpoint `POST /calendar/connect` (mulai OAuth flow), `GET /calendar/events?week=` (fetch event GCal untuk ditampilkan di timeline)

**TASK-T03**
- File: `technical.md`
- Action: MODIFY
- Location: Section 3 (Struktur Repo), folder `backend/app/`
- Change: Tambah folder baru `integrations/google_calendar.py`

---

## Status Keputusan

Semua task di file ini sudah `[RESOLVED]` — tidak ada lagi yang `[BLOCKED]`. Keputusan yang mengunci TASK-P02 & TASK-D02: **Opsi A** — breakdown harian + timebox masuk ke tab Calendar, To-do list tetap checklist apa adanya, struktur final 3 tab (To-do list, Calendar, Profile) sesuai CONST-02.

File ini siap dieksekusi berurutan oleh AI lain, mulai dari TASK-P01.
