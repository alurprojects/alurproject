# Feedback — Status Resolusi B (260917)

**Tanggal:** 17 September 2026
**Konteks:** Semua 6 temuan dari `feedback.md` versi sebelumnya (B1–B6) telah diselesaikan oleh `resolusi-B-260917.md`.

---

## Ringkasan Perubahan yang Dieksekusi

### B1. Auth — Google OAuth Saja ✅
- `auth.md`: Seluruh jalur Email+Password dihapus. File di-rewrite menjadi satu alur Google OAuth saja, dengan satu sketsa Auth Screen tunggal (logo + ilustrasi + tombol Google + teks jaminan keamanan).
- `technical.md`: Baris Auth di Stack Overview sudah tertulis "Supabase Auth (Google OAuth)" — dikonfirmasi konsisten.

### B2. Timeout Vercel → Migrasi ke Render.com ✅
- `DEPLOYMENT_GUIDE.md`: Seluruh Bagian A (Backend) direvisi — target platform berubah dari Vercel serverless ke **Render.com Web Service** (free, tanpa kartu kredit, tanpa timeout). Diagram topologi diperbarui. Catatan "Mitigasi Cold Start" ditambahkan.
- `technical.md`: Baris Deployment di Stack Overview diubah ke "Render.com (Backend) + Vercel (Web)".
- `ENV_GUIDE.md`: Referensi Vercel untuk backend env vars diverifikasi/diperbarui ke Render.

### B3. Endpoint Cron Tanpa Autentikasi ✅
- `DEPLOYMENT_GUIDE.md`: Seluruh path `/debug/run-cron/*` diganti `/internal/cron/*`. Instruksi header `X-Cron-Secret` ditambahkan ke panduan cron-job.org.
- `technical.md`: Subsection baru "Internal/Cron Endpoints" ditambahkan di Section 4 (API Contract). `CRON_SECRET` ditambahkan ke Section 7 (Environment & Secrets).

### B4. CORS Wildcard + Credentials ✅
- `DEPLOYMENT_GUIDE.md`: `allow_origins=["*"]` diganti daftar eksplisit: `["https://alurproject.web.id", "https://www.alurproject.web.id", "http://localhost:3000"]`. Opsi wildcard dihapus termasuk dari komentar.

### B5. Retensi `conversation_logs` — Hybrid Consent + Export ✅
- `DATABASE.md`: Kolom `pending_deletion_notified_at` dan `retention_override` ditambahkan ke tabel `conversation_logs`. Dua cron job baru ditambahkan: `conversation-log-notify-pending` (83 hari) dan `conversation-log-hard-delete` (90 hari).
- `PRD.md`: Section 3.5 (Profile Tab) diperbarui dengan notice banner retensi ([Unduh Backup], [Simpan Selamanya], [Oke, hapus saja]) dan tombol manual "Hapus Riwayat Chat" dengan konfirmasi 2-langkah.
- `technical.md`: 4 endpoint baru ditambahkan: `DELETE /chat/history`, `GET /chat/history/pending-deletion`, `POST /chat/history/export`, `PATCH /chat/history/retention-override`.

### B6. `.env` Master Bocor ke Build Flutter ✅
- `ENV_GUIDE.md`: Section 3C direvisi total — semua referensi `.env` untuk Flutter diganti `.env.client`. Catatan CAUTION ditambahkan. `.vscode/launch.json` diperbarui ke path `.env.client`.
- `ENV_GUIDE.md`: Section 4 ditambahkan langkah baru: "Jika variabel berprefix `PUBLIC_`, tambahkan juga ke `.env.client`."

---

## Status Saat Ini

Semua temuan audit telah ditindaklanjuti. Tidak ada lagi poin terbuka dari `resolusi-audit-260916.md` maupun `resolusi-B-260917.md`.
