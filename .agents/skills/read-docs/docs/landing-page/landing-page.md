# ALUR — Landing Page: Konsep & Copywriting

> **Tanggal:** 2026-10-08 | **Status:** Draft v2 (Revisi Studio Branding)
> **Penulis:** Senior Technical Writer & UI/UX Product Strategist  
> **Konteks:** Persiapan peluncuran (Claude for Startups / Portfolio BakwanSpace)
> **Tujuan:** Menjadi panduan tunggal untuk implementasi Landing Page ALUR — memposisikan ALUR sebagai *flagship product* dari *BakwanSpace Studio*.

---

## 0. Ringkasan Audit Dokumentasi

Sebelum merancang, berikut temuan kunci dari seluruh dokumen proyek yang memengaruhi arah landing page:

| Sumber | Temuan Kunci untuk Landing Page |
| :--- | :--- |
| `PRD.md` §1, §9 | Positioning: *"productivity companion yang secara aktif jujur tentang kapasitas kamu"*. North Star: DCDC. |
| `DESIGN.md` | Warm monochromatic (`#FAF9F7`/`#111111`), Inter font family, no shadows/gradients, editorial feel, 8pt grid. |
| `MOSCOW_FEATURES.md` | 3 masalah inti: (P1) bingung prioritas pagi, (P2) to-do jarang tuntas, (P3) tidak paham pola sendiri. |
| `technical.md` | Backend-heavy architecture. AI ada di belakang layar. Frontend sesederhana kertas. |
| **Studio Hierarchy** | **BakwanSpace (Studio/Lab)** memayungi **ALUR (Product)**. Desain mendukung program "Claude for Startups". |

**Prinsip landing page yang diturunkan:**
1. **Tone jujur, bukan hype.** ALUR tidak menjanjikan "10x productivity". ALUR bertanya: *"Kamu yakin itu semua muat hari ini?"*
2. **Visual bersih, editorial.** Mengikuti `DESIGN.md` — warm off-white, tipografi Inter bold, tanpa noise visual.
3. **Show the AI, don't explain the AI.** User tidak perlu tahu tentang LangGraph atau multi-agent.
4. **Product by Studio.** Menonjolkan ALUR, tetapi dengan kredit "*Built by BakwanSpace Labs*" sebagai kredensial studio.

---

## 1. Hero Section

### 1.1 Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [ALUR logo — wordmark, Inter Black 900, uppercase]         │
│                                                             │
│  Nav: Fitur   Cara Kerja   FAQ          [Mulai Sekarang →]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                     (center-aligned)                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │  [Badge: Built by BakwanSpace Labs]                 │    │
│  │                                                     │    │
│  │  HEADLINE (Inter Black 900, 48–64px, uppercase)     │    │
│  │  "TEMAN YANG JUJUR                                  │    │
│  │   SOAL KAPASITASMU."                                │    │
│  │                                                     │    │
│  │  Sub-headline (Inter Regular 400, 18–20px)          │    │
│  │  "Bukan to-do list yang bilang 'kamu pasti bisa'.   │    │
│  │   ALUR tahu kapan kamu sudah penuh — dan bilang     │    │
│  │   terus terang."                                    │    │
│  │                                                     │    │
│  │  [Mulai Gratis dengan Google →]  ← CTA utama        │    │
│  │                                                     │    │
│  │  Caption: "Tanpa password. Tanpa kartu kredit.      │    │
│  │   Langsung pakai."                                  │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  [Ilustrasi: mockup app minimalis — Daily Focus view        │
│   dengan 3 task dan Morning Brief card di atasnya.          │
│   Style: line-art monokrom, flat, tanpa shadow]             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Value Proposition — Problem-Solution Fit

*(Isi card tetap berfokus pada masalah prioritas pagi, tugas yang menumpuk, dan analisis mingguan seperti yang ada pada copywriting inti.)*

---

## 3. Core Features Showcase

### 3.1 Layout & Content

Berisi pemaparan fitur:
1. **Brain Dump (Tangkap Ide Secepat Pikiran)**
2. **Morning Brief (Pagi Tanpa Bingung)**
3. **Capacity Check (Jujur Soal Batasmu)**

---

## 4. Trust & Differentiator Section

Pemaparan keunikan ALUR:
1. **Honest Capacity** (AI yang meragukan komitmenmu).
2. **FORGOT vs SKIPPED** (Lupa ≠ Sengaja skip).
3. **Invisible Complexity** (UI sederhana seperti kertas, didukung 5 AI agents).

---

## 5. Final CTA & Footer

### 5.1 Footer Layout (Product by Studio)

```
┌─────────────────────────────────────────────────────────────┐
│  ALUR (wordmark, Inter Bold, 14px)                          │
│                                                             │
│  ALUR is an intelligent product experiment designed         │
│  to bring honest capacity planning to daily life.           │
│  [Built with care by BakwanSpace Studio (Link)]             │
│                                                             │
│  Produk: Fitur · Cara Kerja · FAQ                           │
│  Legal: Privasi · Syarat & Ketentuan                        │
│                                                             │
│  © 2026 BakwanSpace. All rights reserved.                   │
│                                                             │
│  Hairline Gray #DEDBD6 divider line ───────────────────     │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Metadata SEO Khusus Studio

| Tag | Content |
| :--- | :--- |
| `<title>` | ALUR by BakwanSpace — Teman yang Jujur Soal Kapasitasmu |
| `<meta name="description">` | ALUR adalah AI productivity companion yang menghitung kapasitasmu, menyusun prioritas pagi, dan jujur saat jadwalmu sudah penuh. Dibangun oleh BakwanSpace Labs. |

---

## Changelog

| Tanggal | Versi | Perubahan |
| :--- | :--- | :--- |
| 2026-10-08 | v1 Draft | Dokumen awal. |
| 2026-10-08 | v2 Draft | Pembaruan hierarki branding *Product by Studio*. Menambahkan atribusi BakwanSpace Labs di Hero dan Footer, serta meta tag spesifik. |
