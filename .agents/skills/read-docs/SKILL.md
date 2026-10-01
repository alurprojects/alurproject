---
name: read-docs
description: >-
  Consult and intelligently extract specifications from project documentation in .agents/skills/read-docs/docs/ 
  (PRD.md, DESIGN.md, technical.md, DATABASE.md, auth.md, ENV_GUIDE.md, DEPLOYMENT_GUIDE.md). 
  Use when designing, implementing, refactoring, or reviewing any feature, UI component, data model, 
  API endpoint, or AI agent in ALUR to ensure strict alignment with project rules and architecture.
---

# Project Documentation Guide: ALUR

> [!IMPORTANT]
> **Single Source of Truth**: Seluruh dokumentasi aktif proyek ALUR berada di folder **`.agents/skills/read-docs/docs/`**.
> Folder `.agents/skills/read-docs/archive/` HANYA berisi arsip historis yang TIDAK BOLEH dirujuk lagi. Jangan pernah membaca dokumen dari `.agents/skills/read-docs/docs/` root atau `.agents/skills/read-docs/archive/`.

Gunakan panduan ini untuk membaca dokumentasi di folder `.agents/skills/read-docs/docs/` secara **cerdas, selektif, dan hemat konteks (progressive disclosure)**. Hindari membaca seluruh file sekaligus jika hanya membutuhkan bagian spesifik.

---

## 1. Peta Dokumen & Kapan Harus Dibaca (Document Routing)

Pilih dokumen yang tepat sesuai konteks pekerjaan yang sedang dikerjakan:

| Kebutuhan / Konteks Tugas | Target Dokumen di `.agents/skills/read-docs/docs/` | Bagian Kunci yang Perlu Dilihat |
| :--- | :--- | :--- |
| **Visi Produk, Positioning, Core Concept, UX Spec, Data Model** | [`PRD.md`](./../../.agents/skills/read-docs/docs/PRD.md) | • §1 (Visi & Positioning)<br>• §2 (Core Concept: Realistic Planner + AI Companion)<br>• §3 (UI/UX: 4-Tab, Hybrid To-do, Chat Room, Web Scope)<br>• §4 (Data Model) |
| **Design System, Warna, Tipografi, Komponen UI, Layout, Tema** | [`DESIGN.md`](./../../.agents/skills/read-docs/docs/DESIGN.md) | • §2 (Color Palette: Warm Off-White, Ink Black, Paper Gray)<br>• §3 (Typography: Inter, H1 uppercase extra-bold, spacing)<br>• §4 (Components: Day Header, Day Strip, Task Row, Chat Room)<br>• §6 (CONST constraints) |
| **Spesifikasi Otentikasi, Sketsa UI Login/SignUp, Alur Auth** | [`auth.md`](./../../.agents/skills/read-docs/docs/auth.md) | • §1 (Metode: Email+Password & Google OAuth)<br>• §2 (Alur Supabase Auth & JWT)<br>• §3 (Sketsa UI Login & SignUp, Form Styling) |
| **Tech Stack, API Endpoint, LangGraph Architecture, Companion Agent** | [`technical.md`](./../../.agents/skills/read-docs/docs/technical.md) | • §1-2 (Stack & Architecture diagram)<br>• §4 (API Contract: /chat/message, /tasks, /internal/cron)<br>• §5 (LangGraph Pipeline & Conditional Routing)<br>• §6 (Companion Agent 2-Tone: HONEST/GENTLE) |
| **Konfigurasi Environment Global, Kredensial, Setup .env** | [`ENV_GUIDE.md`](./../../.agents/skills/read-docs/docs/ENV_GUIDE.md) | • §2 (Konvensi `PUBLIC_*` vs Server-only)<br>• §3 (Integrasi FastAPI, Next.js, Flutter `.env.client`)<br>• §4 (Menambah variabel baru) |
| **Skema Database, SQL Migrasi, RLS, Cron Jobs, ERD** | [`DATABASE.md`](./../../.agents/skills/read-docs/docs/DATABASE.md) | • §2 (ERD incl. conversation_logs)<br>• §5-6 (tasks + conversation_logs DDL & retensi)<br>• §8 (ai_insights + insight_type)<br>• §10 (State machine missed_follow_up)<br>• §11 (pg_cron: nightly, weekly, retention) |
| **Deployment & Hosting** | [`DEPLOYMENT_GUIDE.md`](./../../.agents/skills/read-docs/docs/DEPLOYMENT_GUIDE.md) | • §2 (Backend FastAPI di Vercel Serverless)<br>• §3 (Web Next.js di Vercel)<br>• §4 (DNS Configuration)<br>• §5 (Cron via cron-job.org) |
| **Status Audit & Resolusi** | [`feedback.md`](./../../.agents/skills/read-docs/docs/feedback.md) | • Log resolusi audit B1-B6 dan catatan perbaikan arsitektur |
| **Prioritas Fitur (MoSCoW)** | [`MOSCOW_FEATURES.md`](./../../.agents/skills/read-docs/docs/MOSCOW_FEATURES.md) | • 13 Must / 9 Should / 8 Could / 9 Won't<br>• Peta P1-P3, roadmap R1–R4, metrik DCDC<br>• Keputusan "mendelegasikan = reschedule" |
| **Log Progres Harian** | [`track-progress/YYYY-MM-DD.md`](./../../.agents/skills/read-docs/docs/track-progress/) | • Ringkasan harian, evaluasi MoSCoW, keputusan Web-vs-Mobile, next step |

> [!CAUTION]
> **Dokumen Lama**: Semua file di `.agents/skills/read-docs/archive/` adalah **arsip historis**. Jangan rujuk lagi — gunakan file di `.agents/skills/read-docs/docs/` sebagai satu-satunya source of truth.

---

## 2. Prinsip "Smart & Selective Reading" (Hemat Konteks)

1. **JANGAN dump seluruh file sekaligus** — gunakan pembacaan parsial (`StartLine` & `EndLine` pada `view_file`).
2. **Gunakan pencarian pola lebih dulu (`grep_search`)** — misal: cari `"conversation_logs"` di `DATABASE.md` untuk schema Chat Room.
3. **Cek Fase Implementasi** — Sebelum mengeksekusi kode baru, pastikan fitur sesuai prioritas fase:
   - **Fase 1**: UI Core (4-tab, hybrid to-do, auth, dark/light, Chat Room shell tanpa AI)
   - **Fase 2**: Chat Room + LangGraph (Companion Agent, Extractor, Scheduler, conversation_logs)
   - **Fase 3**: Otonomi penuh (Reflection Agent combined data, cron, voice-to-text, adaptive tuning)

---

## 3. Aturan Kritis Proyek ALUR (Core Invariants)

Saat membaca docs dan menghasilkan solusi/kode, pastikan selalu patuh:

1. **Prinsip UI Minimalis + Backend Canggih**:
   - Frontend sesederhana kertas coretan. Backend secanggih tim asisten pribadi otonom.
   - TIDAK ADA dashboard, grafik tambahan, atau gamifikasi.
2. **Chat Room = Brain-dump Diperluas**:
   - 1 ruang untuk quick capture DAN curhat panjang. AI yang memilah (task/refleksi/curhat).
   - Semua percakapan tersimpan di `conversation_logs` dan jadi bahan evaluasi AI.
3. **Kedaulatan Keputusan Pengguna (DCDC)**:
   - AI TIDAK PERNAH memindahkan task secara sepihak tanpa konfirmasi user.
   - AI hanya saran: *"AI sarankan pindah ke [Hari] · [Terima] [Abaikan]"*
4. **Hybrid To-Do**:
   - Default: Daily Focus (hari ini). Toggle: Weekly accordion (Mon-Sun).
5. **4-Tab Navigation**:
   - To-do, Chat Room, Calendar (read-only), Profile
6. **AI Adaptive Personality**:
   - Companion Agent menyesuaikan nada (WARM/HONEST/MINIMAL/ENCOURAGING) berdasarkan mood, completion rate, dan konteks.
7. **Design Restraint**:
   - Flat design: tanpa shadow, tanpa gradient (kecuali stepped day cascade).
   - Font: Inter. Accent: Vermilion Orange (#FF5420) hanya untuk task done.
