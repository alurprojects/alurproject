---
name: read-docs
description: >-
  Consult and intelligently extract specifications from project documentation in _docs/ 
  (PRD_v3_FINAL.md, DESIGN.md, technical.md, implementation_plan.md). Use when designing, 
  implementing, refactoring, or reviewing any feature, UI component, data model, API endpoint, 
  or AI agent in ALUR to ensure strict alignment with project rules and architecture without 
  wasting token context.
---

# Project Documentation Guide: ALUR

Gunakan panduan ini untuk membaca dokumentasi di folder `_docs/` secara **cerdas, selektif, dan hemat konteks (progressive disclosure)**. Hindari membaca seluruh file sekaligus jika hanya membutuhkan bagian spesifik.

---

## 1. Peta Dokumen & Kapan Harus Dibaca (Document Routing)

Pilih dokumen yang tepat sesuai konteks pekerjaan yang sedang dikerjakan:

| Kebutuhan / Konteks Tugas | Target Dokumen di `_docs/` | Bagian Kunci yang Perlu Dilihat |
| :--- | :--- | :--- |
| **Spesifikasi Produk, UX Spec, Data Model, Filosofi & Aturan Bisnis** | [`PRD_v3_FINAL.md`](./../../_docs/PRD_v3_FINAL.md) | • Section 2 (UI/UX Spec: Accordion, Brain-dump, Inline input)<br>• Section 3 (Data Model: users, goals, tasks)<br>• Section 4 (Rules & Edge Cases) |
| **Design System, Warna, Tipografi, Komponen UI, Layout, Tema** | [`DESIGN.md`](./../../_docs/DESIGN.md) | • Section 2 (Color Palette: Ink Black, Warm Off-White, dll.)<br>• Section 3 (Typography: Inter/General Sans, H1 uppercase)<br>• Section 4 (Component Specs: Accordion strip, Brain-dump button) |
| **Tech Stack, API Endpoint, Arsitektur LangGraph, Supabase/DB, Cron** | [`technical.md`](./../../_docs/technical.md) | • Section 1 & 2 (Stack & Architecture diagram)<br>• Section 4 (API Endpoints spec)<br>• Section 5 (LangGraph Pipeline & Agents)<br>• Section 6 (Supabase & pg_cron) |
| **Konfigurasi Environment Global, Kredensial, Setup .env** | [`ENV_GUIDE.md`](./../../_docs/ENV_GUIDE.md) | • Section 2 (Konvensi `PUBLIC_*` vs Server-only)<br>• Section 3 (Integrasi FastAPI, Next.js, Flutter)<br>• Section 4 (Menambah variabel baru) |
| **Skema Database, SQL Migrasi, RLS, Cron Jobs, ERD** | [`DATABASE.md`](./../../_docs/DATABASE.md) | • Section 2 (ERD / Relasi antar tabel)<br>• Section 3-7 (DDL per tabel + RLS)<br>• Section 9 (State machine `missed_follow_up`)<br>• Section 10 (pg_cron setup)<br>• Section 11 (Urutan migrasi) |
| **Roadmap, Tahapan Fase Pengerjaan (Fase 1/2/3), Task Checklist** | [`implementation_plan.md`](./../../_docs/implementation_plan.md) | • Fase 1 (UI Core tanpa AI)<br>• Fase 2 (Brain-Dump + LangGraph)<br>• Fase 3 (Reflection Agent & Scheduled Jobs) |

> [!CAUTION]
> **Otoritas Dokumen PRD**:
> Selalu jadikan [`PRD_v3_FINAL.md`](./../../_docs/PRD_v3_FINAL.md) sebagai **satu-satunya single source of truth** untuk PRD. Abaikan `PRD.md` lama jika ada perbedaan informasi.

---

## 2. Prinsip "Smart & Selective Reading" (Hemat Konteks)

Untuk menjaga context window tetap bersih dan efisien:

1. **JANGAN dump seluruh file sekaligus**:
   - Gunakan pembacaan parsial (`StartLine` & `EndLine` pada `view_file`) untuk membaca bagian yang relevan saja.
2. **Gunakan pencarian pola lebih dulu (`grep_search`)**:
   - Jika butuh kode warna spesifik (misal: hex Ink Black, Terracotta): cari `"Color Palette"` atau kode `#` di `DESIGN.md`.
   - Jika butuh skema tabel `tasks`: cari `"create table"` atau `"tasks"` di `technical.md` atau `PRD_v3_FINAL.md`.
   - Jika butuh kontrak endpoint: cari nama rute (misal: `/brain-dump`) di `technical.md`.
3. **Cek Fase Implementasi**:
   - Sebelum mengeksekusi kode baru, periksa [`implementation_plan.md`](./../../_docs/implementation_plan.md) untuk memastikan fitur yang dibuat sesuai dengan prioritas fase saat ini (hindari over-engineering fitur Fase 2/3 saat masih di Fase 1).

---

## 3. Aturan Kritis Proyek ALUR (Core Invariants)

Saat membaca docs dan menghasilkan solusi/kode, pastikan selalu patuh pada prinsip non-negotiable ALUR:

1. **Prinsip UI Minimalis (Kertas Coretan)**:
   - **TIDAK ADA** dashboard, grafik, tab tambahan, atau gamifikasi. Antarmuka utama adalah 1 layar accordion mingguan.
   - **Bukan Chat App**: Brain-dump dan klarifikasi task `(?)` dilakukan via input inline 1 baris, BUKAN modal dialog atau antarmuka chat.
2. **Kedaulatan Keputusan Pengguna (DCDC Metric)**:
   - AI **TIDAK PERNAH** memindahkan atau menjadwalkan ulang task secara sepihak tanpa konfirmasi eksplisit dari user.
   - AI hanya memberikan saran 1 baris ringkas: *"AI sarankan pindah ke [Hari] · [Terima] [Abaikan]"*.
3. **Design Restraint**:
   - Flat design: tanpa shadow, tanpa gradient. Pemisah menggunakan border tipis (`Hairline Gray`).
   - Warna `Ink Black (#111111)` HANYA digunakan untuk state aktif atau aksi primer, bukan untuk dekorasi sembarangan.
