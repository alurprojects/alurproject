# resolusi-B-260917.md

**Tujuan**: Menindaklanjuti Section B (`feedback.md`) menjadi instruksi atomik. Format sama seperti `rebuild-260916.md` dan `resolusi-audit-260916.md`.

---

## B3 — Endpoint Cron Tanpa Autentikasi (DISELESAIKAN)

**TASK-B3-01**
- File: `DEPLOYMENT_GUIDE.md`
- Action: MODIFY
- Location: Section 5 (Otomasi Cron)
- Change: Ganti seluruh path `/debug/run-cron/*` jadi `/internal/cron/*`. Tambah instruksi: setiap request ke path ini WAJIB menyertakan header `X-Cron-Secret: <nilai dari env CRON_SECRET>`. Update contoh URL cron-job.org untuk menyertakan header custom ini (cron-job.org mendukung custom header di konfigurasi job-nya)

**TASK-B3-02**
- File: `technical.md`
- Action: ADD
- Location: Section 4 (API Contract), buat subsection baru "Internal/Cron Endpoints"
- Change: Dokumentasikan `POST /internal/cron/{job_name}` dengan catatan: "Middleware FastAPI memvalidasi header `X-Cron-Secret` sebelum request diteruskan ke handler. Request tanpa header ini atau dengan nilai salah → 401. Endpoint ini TIDAK memakai `Authorization: Bearer <supabase_jwt>` seperti endpoint user biasa — ini jalur terpisah khusus sistem-ke-sistem"

**TASK-B3-03**
- File: `technical.md`
- Action: ADD
- Location: Section 7 (Environment & Secrets)
- Change: Tambah `CRON_SECRET` — server-only, dipakai untuk validasi header di atas dan juga sebagai nilai `app.cron_secret` yang sudah dipakai di `DATABASE.md` Section 11 (`pg_cron` → `net.http_post`) — **satu secret yang sama dipakai di 2 tempat**, jangan generate 2 secret berbeda

---

## B4 — CORS Wildcard + Credentials (DISELESAIKAN)

**TASK-B4-01**
- File: `DEPLOYMENT_GUIDE.md`
- Action: MODIFY
- Location: Section 2.1 (CORS Configuration)
- Change: Ganti:
  ```python
  app.add_middleware(
      CORSMiddleware,
      allow_origins=[
          "https://alurproject.web.id",
          "https://www.alurproject.web.id",
          "http://localhost:3000",   # dev Next.js
      ],
      allow_credentials=True,
      allow_methods=["*"],
      allow_headers=["*"],
  )
  ```
  Hapus opsi wildcard `"*"` sepenuhnya dari contoh kode, termasuk dari komentar (jangan ditinggal sebagai "opsi alternatif" — itu yang bikin developer nanti pakai yang salah)

---

## B6 — `.env` Master Bocor ke Build Flutter (DISELESAIKAN)

**TASK-B6-01**
- File: root repo
- Action: ADD
- Location: File baru `.env.client` di root (sejajar `.env`)
- Change: Berisi HANYA variabel berprefix `PUBLIC_*` — di-generate/disalin manual dari `.env`, bukan symlink ke seluruh isi

**TASK-B6-02**
- File: `ENV_GUIDE.md`
- Action: MODIFY
- Location: Section 3C (Mobile App)
- Change: Ganti seluruh instruksi `--dart-define-from-file=../.env` menjadi `--dart-define-from-file=../.env.client`. Tambah catatan:
  ```
  PENTING: mobile app HANYA boleh baca .env.client, tidak pernah .env
  master. Ini mencegah SUPABASE_SERVICE_ROLE_KEY dan API key LLM
  ter-compile ke dalam APK/IPA meski tidak sengaja direferensikan di
  kode Dart — proteksinya di level file, bukan cuma disiplin coding.
  ```

**TASK-B6-03**
- File: `ENV_GUIDE.md`
- Action: MODIFY
- Location: Section 4 (Panduan Menambah Variabel Baru)
- Change: Tambah langkah baru di checklist: "Kalau variabel baru berprefix `PUBLIC_`, tambahkan juga ke `.env.client`, tidak cukup cuma di `.env` master"

**TASK-B6-04**
- File: `.vscode/launch.json` (kalau ada di repo)
- Action: MODIFY
- Location: `toolArgs`
- Change: Ganti path dari `${workspaceFolder}/.env` ke `${workspaceFolder}/.env.client`

---

## B5 — Retensi `conversation_logs` (MEKANISME diputuskan, DURASI menunggu jawaban)

**Keputusan mekanisme** (tidak perlu ditanyakan — ini standar praktik, bukan fork produk): pakai **keduanya**, bukan salah satu — auto-retensi sebagai jaring pengaman default, DAN tombol hapus manual sebagai hak user yang eksplisit.

**TASK-B5-01**
- File: `DATABASE.md`
- Action: ADD
- Location: Section 6 (`conversation_logs`), setelah definisi tabel
- Change: Tambah cron job baru di Section 11:
  ```sql
  -- 4. Conversation Log Retention (harian, hapus log lebih tua dari N hari)
  SELECT cron.schedule(
      'conversation-log-retention',
      '0 3 * * *',  -- jam 03:00 UTC, di luar jam sibuk
      $$
          DELETE FROM conversation_logs
          WHERE created_at < NOW() - INTERVAL '{RETENTION_DAYS} days';
      $$
  );
  ```
  `{RETENTION_DAYS}` menunggu jawaban di chat — lihat opsi

**TASK-B5-02**
- File: `PRD.md`
- Action: ADD
- Location: Section 3.5 (Profile Tab)
- Change: Tambah item: "Tombol 'Hapus Riwayat Chat' — hapus seluruh `conversation_logs` milik user, dengan konfirmasi 2-langkah (bukan 1 tap, karena ini destruktif dan tidak bisa di-undo)"

**TASK-B5-03**
- File: `technical.md`
- Action: ADD
- Location: Section 4 (API Contract)
- Change: Tambah `DELETE /chat/history` — hapus seluruh riwayat chat user yang memanggilnya. Endpoint ini butuh `Authorization: Bearer <supabase_jwt>` seperti biasa (bukan endpoint internal)

---

## B1 — Auth: Google OAuth Saja (DISELESAIKAN)

**TASK-B1-01**
- File: `auth.md`
- Action: REMOVE
- Location: Section 1 (Metode Otentikasi), poin "Email & Password"; Section 2 (Alur Sistem), seluruh sub-bagian yang menyebut `signUp`/password; Section 3 (Sketsa Layar), sketsa "Sign Up" dan "Log In" berbasis form email/password
- Change: Hapus semua jalur Email+Password. Sisakan HANYA alur Google OAuth: `supabase.auth.signInWithOAuth({provider: 'google'})` → trigger `on_auth_user_created` → masuk ke Onboarding/Home

**TASK-B1-02**
- File: `auth.md`
- Action: MODIFY
- Location: Section 3 (Sketsa Layar)
- Change: Ganti 2 sketsa (Log In & Sign Up) jadi 1 sketsa tunggal "Auth Screen": logo ALUR + ilustrasi line-art + 1 tombol "Sign in with Google" + teks kecil "Kami tidak menyimpan password. Datamu aman dengan OAuth." (kalimat ini sebenarnya sudah ada dari `Blueprint v2` lama — tinggal dipakai lagi, jangan ditulis ulang dari nol)

**TASK-B1-03**
- File: `technical.md`
- Action: MODIFY
- Location: Section 1 (Stack Overview), baris "Auth"
- Change: Pastikan tertulis "Supabase Auth (Google OAuth only)" — hapus ambiguitas kalau ada sisa referensi ke email/password di tempat lain di file ini

**TASK-B1-04**
- File: Kode Flutter (`mobile/lib/screens/auth/`)
- Action: REMOVE
- Location: Widget form email/password (kalau sudah sempat dibuat)
- Change: Sisakan 1 tombol Google Sign-In saja

---

## B2 — Timeout Vercel: Render.com, Bukan Fly.io (DIREVISI SETELAH VERIFIKASI)

**Koreksi rekomendasi sebelumnya**: aku sempat menyarankan Fly.io/Railway tanpa mengecek dulu — setelah dicek, Fly.io sudah menghapus free-tier permanennya sejak 2024 (sekarang cuma trial 7 hari lalu wajib kartu kredit). Ini konsisten dengan kekhawatiranmu, jadi rekomendasi direvisi: **Render.com Free Web Service** — gratis tanpa kartu kredit, dan karena berjalan sebagai server biasa (bukan serverless function per-request), tidak ada batas waktu eksekusi keras seperti Vercel. Trade-off: instance tidur setelah idle (~15 menit), request pertama setelah itu butuh ~30-50 detik untuk bangun.

**TASK-B2-01**
- File: `DEPLOYMENT_GUIDE.md`
- Action: MODIFY
- Location: Seluruh Bagian A (Backend FastAPI) — ganti target platform
- Change: Ganti semua instruksi deploy backend dari Vercel serverless ke Render.com Web Service:
  - Buat akun Render.com (tanpa kartu kredit)
  - New → Web Service → connect repo → Root Directory: `backend/`
  - Build Command: `pip install -r requirements.txt`
  - Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
  - Environment Variables: sama seperti daftar lama (SUPABASE_*, GEMINI_API_KEY, dst) — dipindah dari dashboard Vercel ke dashboard Render
  - Plan: **Free**

**TASK-B2-02**
- File: `DEPLOYMENT_GUIDE.md`
- Action: MODIFY
- Location: Section 1 (Topologi Domain)
- Change: Update diagram — `api.alurproject.web.id` sekarang mengarah ke Render (CNAME ke `<service-name>.onrender.com`), bukan lagi ke Vercel project `alur-backend`. `alurproject.web.id` (web Next.js) TETAP di Vercel — tidak berubah, karena Next.js tidak menjalankan rantai multi-agent

**TASK-B2-03**
- File: `DEPLOYMENT_GUIDE.md`
- Action: ADD
- Location: Setelah Bagian A
- Change: Tambah catatan "Mitigasi Cold Start (Opsional)":
  ```
  Render free tier tidur setelah ~15 menit idle. Kalau cold-start 30-50
  detik terasa mengganggu, tambahkan 1 cron job lagi di cron-job.org
  (layanan yang sama yang sudah dipakai untuk nightly/weekly job) yang
  memanggil GET /health setiap 10 menit — ini "membangunkan" instance
  sebelum user beneran butuh. Ini opsional, bukan wajib untuk MVP awal.
  ```

**TASK-B2-04**
- File: `technical.md`
- Action: MODIFY
- Location: Section 1 (Stack Overview), baris "Deployment"
- Change: Ganti "Vercel Free-Tier" jadi "Render.com (Backend, Free Web Service) + Vercel (Web Next.js, Free)" — dua platform berbeda untuk dua komponen, bukan 1 platform untuk semua

**TASK-B2-05**
- File: `ENV_GUIDE.md`
- Action: MODIFY
- Location: Bagian mana pun yang menyebut Vercel sebagai tempat backend environment variables diisi
- Change: Ganti referensi dashboard Vercel jadi dashboard Render untuk variabel server-only

---

## B5 — Retensi `conversation_logs`: Hybrid Consent + Export (DIREVISI)

**Revisi dari rencana awal**: bukan auto-hapus diam-diam, tapi **beri tahu dulu + sediakan cara backup lokal** sebelum data benar-benar hilang. Ini menggantikan TASK-B5-01 versi sebelumnya (cron `DELETE` langsung).

**TASK-B5-01 (REVISI)**
- File: `DATABASE.md`
- Action: MODIFY
- Location: Section 6 (`conversation_logs`), tambah kolom
- Change: Tambah 2 kolom:
  ```sql
  ALTER TABLE conversation_logs
    ADD COLUMN pending_deletion_notified_at TIMESTAMPTZ,
    ADD COLUMN retention_override BOOLEAN NOT NULL DEFAULT FALSE;
  ```
  `retention_override = TRUE` berarti log ini dikecualikan dari auto-hapus selamanya (user pilih "Simpan Selamanya")

**TASK-B5-02 (REVISI)**
- File: `DATABASE.md`
- Action: MODIFY
- Location: Section 11 (Cron Jobs)
- Change: Ganti cron retensi jadi 2 tahap, bukan 1 `DELETE` langsung:
  ```sql
  -- 4a. Tandai log yang mendekati batas retensi (83 hari, beri jeda 7 hari
  --     sebelum dihapus permanen di 90 hari)
  SELECT cron.schedule(
      'conversation-log-notify-pending',
      '0 4 * * *',
      $$
          UPDATE conversation_logs
          SET pending_deletion_notified_at = NOW()
          WHERE created_at < NOW() - INTERVAL '83 days'
            AND pending_deletion_notified_at IS NULL
            AND retention_override = FALSE;
      $$
  );

  -- 4b. Hapus permanen log yang sudah diberi notice >= 7 hari DAN
  --     tidak di-override user
  SELECT cron.schedule(
      'conversation-log-hard-delete',
      '0 5 * * *',
      $$
          DELETE FROM conversation_logs
          WHERE pending_deletion_notified_at < NOW() - INTERVAL '7 days'
            AND retention_override = FALSE;
      $$
  );
  ```

**TASK-B5-03**
- File: `technical.md`
- Action: ADD
- Location: Section 4 (API Contract)
- Change: Tambah 3 endpoint:
  - `GET /chat/history/pending-deletion` — daftar log yang `pending_deletion_notified_at IS NOT NULL` (untuk ditampilkan sebagai notice di Profile)
  - `POST /chat/history/export` — kembalikan seluruh riwayat chat user sebagai JSON/text untuk diunduh (ini yang jadi "backup lokal ganda")
  - `PATCH /chat/history/retention-override` — set `retention_override = TRUE` untuk log yang dipilih user ("Simpan Selamanya")

**TASK-B5-04**
- File: `PRD.md`
- Action: MODIFY
- Location: Section 3.5 (Profile Tab) — ganti isi TASK-B5-02 versi sebelumnya
- Change:
  ```
  Notice banner (muncul HANYA kalau ada log berstatus pending-deletion):
  "X riwayat chat lebih dari 83 hari akan dihapus permanen dalam 7 hari."
  [Unduh Backup] → trigger POST /chat/history/export, simpan sebagai file
                    lokal di device (Downloads/Files app)
  [Simpan Selamanya] → PATCH retention-override untuk log tersebut
  [Oke, hapus saja] → tidak melakukan apa-apa, biarkan cron jalan normal
  ```
  Tombol "Hapus Riwayat Chat" manual (hapus semua, kapan saja) tetap ada terpisah dari mekanisme notice ini.
