# Implementation Plan: ALUR Rebuild (4-Tab & Chat Room)

Berdasarkan `PRD.md`, `DESIGN.md`, `ENV_GUIDE.md`, `DEPLOYMENT_GUIDE.md` dan dokumentasi teknis terbaru di `_docs/running/`, berikut adalah rencana implementasi bertahap.

## Fase 1 — Otentikasi, UI Core & Fondasi (Tanpa AI)

Fokus: Setup environment, Auth Google OAuth, struktur navigasi 4-Tab, UI Hybrid To-do, dan shell UI Chat Room.

### 1.1. Konfigurasi Environment & Otentikasi

- [x] **Environment**: Konfigurasi Flutter untuk menggunakan `--dart-define-from-file=../.env.client` saat *run* dan *build* agar aman (sesuai `ENV_GUIDE.md`).
- [x] Siapkan konfigurasi Supabase Auth di Dashboard (Google OAuth Provider).
- [x] Buat trigger database `on_auth_user_created` untuk sinkronisasi otomatis ke tabel `public.users`.
- [x] Jalankan migrasi Supabase untuk tabel inti, termasuk `conversation_logs` (retensi), `cron_batch_state`, dan fungsi `users_active_this_week()`.
- [x] **Frontend (UI Auth):** Bangun halaman `AuthScreen` khusus Google OAuth (tanpa Email/Password) mengikuti standar palet `AppColors` di `DESIGN.md`.
- [x] **Frontend (Logika):** Implementasikan fungsi login `Sign in with Google` menggunakan `supabase-flutter`.
- [x] Buat `AuthGate` untuk me-*redirect* user ke `MainScreen` jika sudah login, atau ke `AuthScreen` jika belum.
- [x] Setup penyimpanan sesi (Supabase Persistence) untuk mempertahankan otentikasi.

### 1.2. Navigasi & Layout Utama

- [x] Buat `MainScreen` dengan `BottomNavigationBar` 4-Tab (To-do, Chat Room, Calendar, Profile).
- [x] Pastikan navigasi antar tab berjalan mulus dengan state yang tersimpan.

### 1.3. Tab 1: To-do (Hybrid View)

- [x] Implementasikan **Daily Focus View** (Tampilan default, hanya hari ini).
- [x] Tambahkan fitur *swipe* kiri/kanan untuk berpindah hari pada Daily Focus.
- [x] Tambahkan tombol *toggle* untuk beralih ke **Weekly Overview** (Accordion Mon-Sun).
- [x] Integrasikan `TaskRow` dan fungsi centang manual (CRUD status ke database).

### 1.4. Tab 2: Chat Room (UI Shell)

- [x] Bangun antarmuka Chat Room sederhana (bubble chat user & AI).
- [x] Buat input teks di bagian bawah dan integrasikan akses cepat *brain-dump* dari tab To-do.
- [x] *(Mock)* Buat fungsi agar pesan user muncul di layar (belum terhubung ke backend).

### 1.5. Tab 3 & 4: Calendar & Profile

- [x] Buat UI statis untuk Calendar (Time-block grid 06:00 - 22:00, Read-Only).
- [x] Buat halaman Profile menampilkan informasi user dan setting standar (theme, timezone, daily_capacity_hours).
- [x] **Data Retention UI (Profile):** Implementasikan *Notice Banner* jika ada chat yang berstatus *pending-deletion* (>83 hari).
- [x] **Data Retention UI (Profile):** Sediakan opsi: [Unduh Backup] (JSON), [Simpan Selamanya], dan tombol destruktif "Hapus Riwayat Chat" dengan konfirmasi 2-langkah.

### 1.6. Web App (MVP)

- [x] Konfigurasi build Web (Next.js & Flutter Web) untuk merender antarmuka To-do dan Calendar saja (Chat Room & Profile tidak diaktifkan pada v1 web, sesuai `PRD.md` & `DEPLOYMENT_GUIDE.md`).
- [x] Verifikasi build Web production (`npm run build` sukses 0 errors, static export siap deploy Vercel).

---

## Fase 2 — Chat Room & LangGraph Backend

Fokus: Menghidupkan Chat Room dengan kecerdasan buatan (Companion & Extractor) dan menyiapkan endpoint retensi.

### 2.1. Backend (FastAPI & LangGraph)

- [x] Setup *environment* FastAPI dan deploy ke **Vercel Serverless (Tahap 1)**. *Catatan:* Perhatikan limit eksekusi 10 detik; persiapkan fallback arsitektur manual (tanpa LangGraph) ke Cloudflare Workers jika limit ini menjadi kendala kritis pada endpoint real-time.
- [x] Konfigurasi CORS pada FastAPI dengan *strict mode* (jangan gunakan wildcard `*`) sesuai `DEPLOYMENT_GUIDE.md`.
- [x] Buat endpoint inti: `POST /chat/message` dan `GET /chat/history`.
- [x] Buat endpoint retensi data: `POST /chat/history/export`, `PATCH /chat/history/retention-override`, dan `DELETE /chat/history`.
- [x] Implementasikan **Companion Agent** dengan **2-Tone Persona (HONEST/GENTLE)**.
- [x] Implementasikan **Extractor Agent** (Mengekstrak teks menjadi struktur task JSON, *is_ambiguous* flag).
- [x] Implementasikan **Scheduler Agent** (Menentukan `assigned_date` berfokus pada kapasitas realistis).
- [x] Rangkai agent menggunakan **LangGraph** dengan *conditional routing*. Gunakan **Groq sebagai primary LLM** untuk jalur real-time agar inference berjalan super cepat (< 10 detik).

### 2.2. Integrasi Frontend

- [x] Hubungkan UI Chat Room di Flutter ke endpoint `POST /chat/message`.
- [x] Tampilkan indikator *typing* saat menunggu respons backend (handle timeout Vercel dengan elegan).
- [x] Pastikan task yang diekstrak oleh AI langsung muncul secara reaktif di tab To-do.

---

## Fase 3 — Otonomi Penuh & Cron Jobs

Fokus: Refleksi otomatis, penjadwalan ulang, perlindungan data, dan tuning kepribadian.

### 3.1. Reflection & Cron Jobs

- [x] Buat tabel `ai_insights`, `task_suggestions`, dan tabel pendukung cron `cron_batch_state`.
- [x] Implementasikan helper function SQL `users_active_this_week()` di Supabase.
- [x] Implementasikan **Reflection Agent** yang membaca data gabungan (`tasks` + `conversation_logs`). Gunakan **Gemini 2.0 Flash sebagai primary LLM** di jalur cron ini untuk reasoning yang lebih baik.
- [x] Setup endpoint cron di FastAPI untuk dipicu layanan eksternal (cron-job.org) menggunakan otorisasi header `X-Cron-Secret` (untuk `nightly-status-check`, `weekly-reflection`, dan `weekly-recurrence-generator`).
- [x] Implementasikan mekanisme **Batching** pada `weekly-reflection` (memproses user bertahap) dan gunakan parameter `?only_active=true` untuk menghindari *timeout* Vercel saat user bertambah.
- [x] Setup `pg_cron` di Supabase untuk eksekusi panggilan HTTP POST ke endpoint internal.
- [x] Setup `pg_cron` di Supabase untuk `conversation-log-notify-pending` (Peringatan H-7 hapus log chat).
- [x] Setup `pg_cron` di Supabase untuk `conversation-log-hard-delete` (Hapus chat >90 hari jika tidak ada *retention override*).

### 3.2. Fitur Lanjutan (Mobile & Backend)

- [x] Hubungkan logika *Adaptive Personality* pada Companion Agent (menyesuaikan *tone* berdasarkan tingkat penyelesaian task & insight dari Reflection Agent).
- [x] Implementasikan alur **Follow-up Chip** di UI untuk task yang bersatus `MISSED` (opsi: FORGOT / SKIPPED / RESCHEDULED).
- [ ] *(Opsional Fase 3)* Implementasikan input suara (Voice-to-Text) di Chat Room menggunakan Gemini Audio API atau plugin *speech-to-text* lokal.

notes:
1. berdasarkan psikologi user, maksudnya user bisa konsultasi tentang masalahnya kenapa kok to do list nya selalu menumpuk, lalu AI akan memberikan solusi berdasarkan insight dari Reflection Agent. Nantinya bisa menjadi bahan pertimbangan AI untuk memberikan solusi yang lebih baik.
2. 