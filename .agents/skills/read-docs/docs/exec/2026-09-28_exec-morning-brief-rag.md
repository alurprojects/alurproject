# Execution Plan: Morning Brief & RAG Integration

> **Referensi Plan**: [2026-09-28_morning-brief-rag.md](../plans/2026-09-28_morning-brief-rag.md)  
> **Tanggal**: 2026-09-28  
> **Role**: Expert Technical Project Manager  

Dokumen ini berisi rincian eksekusi step-by-step untuk mengimplementasikan fitur Morning Brief dan RAG Pipeline. Silakan centang (`[x]`) pada setiap langkah yang sudah diselesaikan.

---

## Phase 1: Database & Infrastructure Setup (Supabase)

Fase ini fokus pada persiapan skema database dan fungsi vector untuk RAG.

- [x] **1.1 Migration: Enable pgvector**
  - Buat file migrasi `012_enable_pgvector.sql`.
  - Tambahkan perintah `CREATE EXTENSION IF NOT EXISTS vector;`.
- [x] **1.2 Migration: Embeddings Table**
  - Buat file migrasi `013_create_embeddings.sql`.
  - Definisikan ENUM `embedding_source`.
  - Buat tabel `embeddings` dengan kolom `embedding vector(768)`.
  - Tambahkan index IVFFLAT (`vector_cosine_ops`).
  - Terapkan Row Level Security (RLS) untuk `embeddings`.
- [x] **1.3 Migration: Match Embeddings RPC**
  - Buat fungsi SQL `match_embeddings` untuk similarity search menggunakan `cosine distance`.
- [x] **1.4 Migration: Morning Briefs Table**
  - Buat file migrasi `014_create_morning_briefs.sql`.
  - Buat tabel `morning_briefs` dengan JSONB `content`.
  - Terapkan Row Level Security (RLS).
- [x] **1.5 Migration: Core Profile Schema**
  - Buat file migrasi `016_add_ai_profile_summary.sql`.
  - Tambahkan kolom `ai_profile_summary JSONB DEFAULT '{}'` di tabel `users`.
- [x] **1.6 Verifikasi Skema**
  - Eksekusi `supabase db push` / apply migrations ke instance lokal.
  - Verifikasi tabel, kolom, dan ekstensi vector aktif.

---

## Phase 2: RAG Pipeline & Core Services (Backend)

Membangun fondasi logika untuk RAG (Embedding & Retrieval).

- [x] **2.1 Implementasi `EmbeddingService`**
  - Buat file `backend/app/services/embedding_service.py`.
  - Integrasikan LLM Gemini (`text-embedding-004`) untuk men-generate vector.
  - Buat fungsi `upsert_embedding` untuk menyimpan ke tabel `embeddings`.
  - Buat fungsi `similarity_search` yang memanggil RPC `match_embeddings`.
- [x] **2.2 Implementasi `RAGService`**
  - Buat file `backend/app/services/rag_service.py`.
  - Buat fungsi `retrieve_context` untuk mengambil dan memformat konteks dari database.
  - Buat fungsi `generate_grounded_prompt` untuk menyusun prompt berbasis RAG.

---

## Phase 3: Integration & Hooks (Backend)

Menghubungkan aksi user dengan pipeline embedding agar database vektor terus ter-update.

- [x] **3.1 Hook: Chat Logs (`chat.py`)**
  - Modifikasi endpoint `/chat/message`.
  - Panggil `upsert_embedding` setelah pesan baru tersimpan di `conversation_logs`.
- [x] **3.2 Hook: Tasks (`tasks.py`)**
  - Modifikasi endpoint pembuatan dan pembaruan task (`POST` & `PATCH`).
  - Panggil `upsert_embedding` setelah state task berubah.
- [x] **3.3 Integrasi Companion Agent (`companion.py`) - Hermes Style**
  - Buat logic `Dynamic Persona Router` (pilih salah satu dari 4 modul persona: Honest, Gentle, Strategist, Minimalist).
  - Ubah `CompanionAgent` untuk menggunakan "3-Layer Hierarchical Memory".
  - Gabungkan Core Profile (JSON), 3-5 pesan terakhir (Short-term), dan `rag_service.retrieve_context` (Long-term/Archival).
- [x] **3.4 Background Memory Condenser (Cron)**
  - Buat fungsi/service untuk mengompresi chat harian menjadi metadata `ai_profile_summary`.
  - Jadwalkan sebagai cron nightly (`background_memory_condenser`) untuk meng-update tabel `users`.

---

## Phase 4: Morning Brief Logic (Backend & Cron)

Mengatur pembuatan konten Morning Brief dan trigger notifikasinya.

- [x] **4.1 Implementasi `MorningBriefService`**
  - Buat file `backend/app/services/morning_brief_service.py`.
  - Buat fungsi `generate_brief` (kalkulasi sisa kapasitas, query task pending/missed).
  - Integrasikan LLM via `RAGService` untuk men-generate `ai_note` (pesan motivasi/insight).
- [x] **4.2 API Endpoint: GET `/morning-brief`**
  - Tambahkan endpoint di `backend/app/api/morning_brief.py`.
  - Buat logika on-demand generation jika brief belum dibuat oleh cron.
- [x] **4.3 Cron API Endpoint**
  - Tambahkan endpoint `POST /internal/cron/morning-brief`.
  - Buat logika pencarian user berdasarkan `reminder_hour` dan timezone aktif.
- [x] **4.4 Cron Job Schedule**
  - Update `011_setup_pg_cron.sql` (atau buat migrasi baru) untuk menambahkan trigger harian (tiap jam) yang memanggil `/internal/cron/morning-brief`.

---

## Phase 5: Frontend Implementation (Mobile - Flutter)

Membangun UI interaktif untuk merespons Morning Brief.

- [x] **5.1 Widget: `MorningBriefBanner`**
  - Buat file `mobile/lib/widgets/morning_brief_banner.dart`.
  - Buat desain banner sesuai spesifikasi UI ALUR (Soft Card, Paper Gray background).
- [x] **5.2 Interaksi & Quick Actions**
  - Hubungkan tombol `[Edit]` dan `[❌]` ke API Tasks.
  - Hubungkan tombol `[+ Tambah task]` ke inline form.
  - Hubungkan tombol `[💬 Cerita ke AI]` untuk deep-linking/navigasi ke tab Chat Room.
- [x] **5.3 Integrasi ke `TodoScreen`**
  - Modifikasi `mobile/lib/screens/todo/todo_screen.dart` (`weekly_screen.dart` Daily Focus).
  - Tampilkan `MorningBriefBanner` di bagian paling atas ketika view "Daily Focus" aktif (jika ada data morning brief hari ini).

---

## Phase 6: Testing & Verification

Validasi bahwa semua komponen bekerja sama dengan baik.

- [x] **6.1 Backend Unit Tests**
  - Uji `EmbeddingService` dan `RAGService`.
  - Pastikan vektor tersimpan dan similarity search memberikan skor yang sesuai.
- [x] **6.2 RAG Accuracy Test**
  - Simulasikan input pesan lampau, dan pastikan Companion Agent bisa menjawab menggunakan context RAG tanpa halusinasi.
- [x] **6.3 Morning Brief Payload Test**
  - Jalankan test cron endpoint, verifikasi output JSONB tersimpan benar di `morning_briefs`.
- [x] **6.4 UI/UX Verification**
  - Buka app, pastikan Banner muncul, test setiap fungsi aksi cepat (Quick Actions) secara manual.
