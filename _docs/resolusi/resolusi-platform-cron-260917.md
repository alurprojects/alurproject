# resolusi-platform-cron-260917.md

**Tujuan**: Mengunci rencana platform bertahap (Vercel → Cloudflare → VPS) dan membuat cron jobs efisien — dua hal ini saling terkait karena batas 10 detik Vercel berlaku juga ke endpoint cron.

---

## 1. Rencana Platform Bertahap (Governing Decision)

```
TAHAP 1 (sekarang): Vercel Free-Tier
   │  Tetap dipakai selama LangGraph chain + cron batch bisa selesai < 10 detik
   │  per invocation. Optimasi wajib: lihat Section 2.
   ▼
TAHAP 2 (kalau Tahap 1 mentok): Cloudflare Workers Free-Tier
   │  ✅ TERVERIFIKASI (Sep 2026): FastAPI & LangChain resmi didukung
   │     sebagai package bawaan Python Workers.
   │  ⚠️  TAPI dengan batasan nyata, bukan sekadar redeploy:
   │     - LangGraph TIDAK disediakan — perlu ditulis ulang jadi state
   │       machine manual (plain Python, tanpa LangGraph) untuk graph
   │       sekecil punya kita, ini realistis dikerjakan.
   │     - Cuma langchain-openai yang disediakan, bukan langchain-groq/
   │       langchain-google-genai — panggil Gemini/Groq via HTTP
   │       langsung (aiohttp/httpx2), bukan lewat wrapper LangChain.
   │     - Versi LangChain yang disediakan sudah lama (0.1.8) — kalau
   │       tetap pakai LangChain sama sekali, sebaiknya cuma untuk
   │       PromptTemplate/parsing sederhana, jangan andalkan fitur baru.
   │     - Python Workers masih open beta; deploy package pip ke
   │       production kemungkinan masih butuh daftar closed-beta —
   │       cek status ini lagi saat benar-benar mau eksekusi.
   ▼
TAHAP 3 (kalau Tahap 2 juga tidak memungkinkan): VPS Berbayar
   │  Sudah dibahas sebelumnya (NAT VPS + Cloudflare Tunnel, atau
   │  provider lain). Tanpa batas eksekusi, tapi sudah bukan "zero cost".
```

**TASK-PLAT-01**
- File: `DEPLOYMENT_GUIDE.md`
- Action: MODIFY
- Location: Note box di paling atas + seluruh Bagian A
- Change: Ganti catatan status jadi menjelaskan 3 tahap di atas secara eksplisit (bukan cuma "sementara, nanti ke VPS" seperti sekarang). Judul Bagian A tetap "Deployment ke Vercel" untuk Tahap 1, tapi tambah subsection "Kapan Pindah ke Tahap 2/3?" dengan kriteria konkret: *"Pindah kalau endpoint `/chat/message` ATAU `/internal/cron/reflection` mulai return 504 Gateway Timeout secara konsisten (bukan sesekali) — pantau lewat log/observability Section 10 `technical.md`."*

**TASK-PLAT-02**
- File: `technical.md`
- Action: MODIFY
- Location: Section 1 (Stack Overview), baris Deployment
- Change: Ganti jadi "Vercel Free-Tier (Tahap 1) — fallback: Cloudflare Workers *[perlu verifikasi dukungan Python sebelum eksekusi]* → VPS berbayar (Tahap 3)"

---

## 2. Optimasi Wajib Supaya Tahap 1 (Vercel) Bertahan Lebih Lama

### 2.1 Model Selection — Groq untuk Jalur Real-Time

**TASK-CRON-01**
- File: `technical.md`
- Action: MODIFY
- Location: Section 1 (Stack Overview), baris LLM Provider
- Change: Ganti urutan prioritas — **Groq jadi primary untuk jalur real-time** (`/chat/message`, Companion+Extractor+Scheduler), Gemini jadi primary untuk jalur batch/cron (toleransi latensi lebih tinggi, kualitas reasoning lebih diutamakan di sana). Alasan: Groq secara konsisten lebih cepat untuk inference, penting untuk tetap di bawah 10 detik Vercel

### 2.2 Skip User Tidak Aktif (Jangan Boroskan LLM Call)

**TASK-CRON-02**
- File: `DATABASE.md`
- Action: ADD
- Location: Sebelum Section 11 (Cron Jobs), tambah query helper
- Change: Tambah fungsi SQL untuk filter user aktif:
  ```sql
  CREATE OR REPLACE FUNCTION users_active_this_week()
  RETURNS TABLE(user_id UUID) AS $$
      SELECT DISTINCT u.id
      FROM users u
      WHERE EXISTS (
          SELECT 1 FROM tasks t
          WHERE t.user_id = u.id AND t.updated_at > NOW() - INTERVAL '7 days'
      ) OR EXISTS (
          SELECT 1 FROM conversation_logs c
          WHERE c.user_id = u.id AND c.created_at > NOW() - INTERVAL '7 days'
      );
  $$ LANGUAGE sql STABLE;
  ```
  User tanpa aktivitas 7 hari terakhir dilewati sepenuhnya oleh `weekly-reflection` — tidak ada gunanya menganalisis user yang tidak buka app, dan ini langsung mengurangi jumlah LLM call per run

**TASK-CRON-03**
- File: `DATABASE.md`
- Action: MODIFY
- Location: Section 11, cron `weekly-recurrence-generator` dan `weekly-reflection`
- Change: Tambah parameter `?only_active=true` di URL yang dipanggil `net.http_post`, backend memakai `users_active_this_week()` sebelum memulai loop per-user

### 2.3 Batching Supaya Tidak Timeout Kalau User Bertambah

**TASK-CRON-04**
- File: `DATABASE.md`
- Action: ADD
- Location: Tabel baru, sebelum Section 11
- Change: Tambah tabel kecil untuk tracking batch progress:
  ```sql
  CREATE TABLE cron_batch_state (
      job_name      TEXT PRIMARY KEY,
      last_user_id  UUID,
      run_date      DATE NOT NULL,
      completed     BOOLEAN NOT NULL DEFAULT FALSE
  );
  ```

**TASK-CRON-05**
- File: `technical.md`
- Action: ADD
- Location: Section 5 (LangGraph Node Detail), tambah subsection
- Change: Tambah penjelasan pola batching untuk `weekly-reflection`:
  ```
  Karena tiap invocation Vercel dibatasi ~10 detik, weekly-reflection
  TIDAK memproses semua user aktif dalam 1 kali panggilan begitu jumlah
  user bertambah. Pola yang dipakai:

  1. Endpoint /internal/cron/reflection ambil batch kecil (misal 5 user)
     dari users_active_this_week(), mulai dari last_user_id di
     cron_batch_state (kalau NULL/run_date beda, mulai dari awal)
  2. Proses 5 user itu, update last_user_id, kalau masih ada sisa →
     return signal "continue"
  3. cron-job.org dikonfigurasi memanggil endpoint ini berulang setiap
     1 menit (bukan cuma sekali) sampai completed = TRUE
  4. Kalau jumlah user masih kecil (MVP awal, <30 user aktif/minggu),
     1 batch kemungkinan besar sudah cukup — mekanisme ini baru benar-
     benar diuji begitu user bertambah, tapi strukturnya sudah siap
     dari awal supaya tidak perlu migrasi skema nanti.
  ```

### 2.4 Index Baru untuk Query Retensi (Ditemukan Saat Audit — Belum Ada)

**TASK-CRON-06**
- File: `DATABASE.md`
- Action: ADD
- Location: Section 6 (`conversation_logs`), tambah ke bagian Index
- Change: Index untuk 2 cron retensi (`conversation-log-notify-pending`, `conversation-log-hard-delete`) belum ada — tanpa ini, query-nya full-table-scan begitu tabel membesar:
  ```sql
  CREATE INDEX conversation_logs_retention_notify_idx
      ON conversation_logs (created_at)
      WHERE pending_deletion_notified_at IS NULL AND retention_override = FALSE;

  CREATE INDEX conversation_logs_retention_delete_idx
      ON conversation_logs (pending_deletion_notified_at)
      WHERE pending_deletion_notified_at IS NOT NULL AND retention_override = FALSE;
  ```

---

## 3. Yang TIDAK Diubah (Sudah Efisien, Konfirmasi Saja)

- `nightly-status-check` (jalan tiap jam): TETAP seperti sekarang — cuma 1 `UPDATE` SQL langsung tanpa LLM, sudah pakai index `(user_id, assigned_date)`, tidak perlu batching karena tidak pernah panggil AI
- `conversation-log-notify-pending` & `conversation-log-hard-delete`: query-nya tetap sederhana, cuma butuh index baru (TASK-CRON-06), bukan restrukturisasi

---

## 4. Catatan untuk Sesi Berikutnya

Status verifikasi Tahap 2 (Cloudflare) sudah lebih jelas dibanding sesi sebelumnya: FastAPI & LangChain memang didukung, tapi LangGraph tidak, dan provider Gemini/Groq via LangChain juga tidak. Kalau nanti benar-benar butuh eksekusi ke Tahap 2, siapkan dulu versi hand-rolled dari agent graph (tanpa LangGraph) sebagai bagian dari perpindahan — bukan asumsi "pasti bisa redeploy apa adanya". Cek juga status closed-beta package deployment Cloudflare saat itu, karena open-beta bisa berubah status kapan saja.
