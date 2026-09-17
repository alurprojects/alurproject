# Design System: ALUR

**Visi Desain:** Tenang, lapang (*airy*), dan minimalis fungsional. ALUR mengadopsi gaya visual monokromatik hangat yang bersih — bukan hitam-putih murni, melainkan *warm off-white* dan *ink black* yang lebih lembut di mata. Identitas utamanya terletak pada *whitespace* melimpah, tipografi geometris bold uppercase untuk day headers, dan komponen accordion/day-strip yang sudah tervalidasi.

---

## 1. Visual Theme & Atmosphere
Tema visual ALUR berfokus pada suasana *calm, matte paper workspace*. Desain bergaya editorial dan tactile, memberikan kesan tenang bagi pengguna. Semua layar menggunakan latar *warm off-white* yang tidak menyilaukan, tanpa bayangan (shadows), dan tanpa gradasi (gradients). Lengkungan sedang (*slight rounded corners*) digunakan untuk kesan modern.

---

## 2. Color Palette & Roles

### Primary Foundation
- **Warm Off-White (`#FAF9F7`)** — Background utama aplikasi.
- **Paper Gray (`#F0EFED`)** — Surface sekunder, latar day-strip collapsed, latar card.

### Anchor & Interactive
- **Ink Black (`#111111`)** — SATU-SATUNYA aksen kuat. Dipakai untuk *active state* & *primary action* saja, tidak dekoratif.

### Typography & Text
- **Charcoal (`#1A1A1A`)** — Teks utama (body, task title).
- **Warm Gray (`#7A7772`)** — Teks sekunder, meta, placeholder.
- **Hairline Gray (`#DEDBD6`)** — Border, divider tipis antar elemen.

---

## 3. Typography Rules

**Primary Font Family:** Inter — geometric sans-serif, tight tracking, crisp editorial feel.

### Hierarchy & Weights
- **Day Headers (H1):** Extra-bold (800), uppercase, tight letter-spacing (-0.02em). Ukuran ditentukan oleh konteks tampilan (Daily Focus vs Day Strip).
- **Section Headers (H2):** Semi-Bold (600), ukuran 16px, Charcoal.
  - **Line-height:** 24px. Margin bawah: 16px.
- **Body Text / Task Text:** Regular (400), ukuran 14px, Charcoal.
  - **Line-height:** 20px.
- **Muted/Meta Text:** Regular (400), ukuran 12px, Warm Gray.
  - **Line-height:** 16px.

### Spacing Principles (The 8pt Grid System)
Semua jarak, margin, dan padding **harus merupakan kelipatan dari 4px atau 8px**.
- **Micro spacing (4px - 8px):** Jarak antara teks tugas dan ikon, antara judul dan deskripsi kecil.
- **Component spacing (16px - 24px):** Jarak antar tugas dalam satu list, padding dalam tombol/card.
- **Section spacing (32px - 48px):** Whitespace besar untuk memisahkan antar blok konten utama.

---

## 4. Component Stylings

### Day Header (Active/Expanded)
Header hari aktif ditampilkan dengan teks uppercase extra-bold berukuran besar. Background menggunakan Warm Off-White. Tidak menggunakan warna solid Ink Black sebagai latar — Ink Black hanya untuk interaksi.

### Day Strip (Collapsed)
Hari yang tidak aktif ditampilkan sebagai strip horizontal minimalis dengan latar **Paper Gray (`#F0EFED`)**. Teks hari uppercase bold, vertically centered.

### Task Row
- **Checkbox:** Lingkaran outline tipis (Hairline Gray border). Saat dicentang → terisi **Ink Black** penuh dengan ikon centang putih.
- **Task Text:** Regular 14px Charcoal. Saat selesai: strikethrough + Warm Gray.
- **Dividers:** Garis batas bawah sangat tipis (1px Hairline Gray).
- **Metadata:** Informasi tambahan (estimasi waktu, kategori) ukuran 12px Warm Gray.

### Follow-up / Reschedule Chip
Chip ringkas berbentuk kapsul (pill) dengan border Hairline Gray, teks Warm Gray. Muncul pada task dengan status `missed_follow_up = PENDING`.

### Buttons (Tombol)
- **Primary Button:** Persegi panjang, sudut membulat moderat (`border-radius: 6px` - `8px`). Latar Ink Black, teks putih, font Semi-Bold.
- **Floating Action Button (FAB):** Lingkaran penuh, latar Ink Black, ikon "+" putih. Melayang di sudut kanan bawah.

### Cards & Grouping
- **Soft Cards:** Latar Paper Gray, tanpa border luar, tanpa shadow. Sudut melengkung halus (8px - 12px).
- **Section Separation:** Mengutamakan whitespace, bukan garis kotak.

### Chat Room Components
- **Message bubbles:** Sudut melengkung halus (8px).
- **User message:** Latar Paper Gray, teks Charcoal, tanpa border.
- **AI message:** Latar Warm Off-White dengan border tipis Hairline Gray, teks Charcoal.
- **Input area:** Persegi panjang, sudut membulat halus, menempel di bagian bawah layar.

### Bottom Navigation (4 Tab)
| Posisi | Ikon | Tab |
| :--- | :--- | :--- |
| 1 | checklist/home outline | To-do |
| 2 | chat/message outline | Chat Room |
| 3 | calendar outline | Calendar |
| 4 | person/user outline | Profile |

**Active:** Ikon Ink Black solid + label kecil. **Inactive:** Ikon outline Warm Gray.

### Illustrations & Imagery
Line-art monokrom hitam-putih, gaya terstruktur dan rapi. Warna isi (fill) menggunakan Charcoal/Ink Black untuk aksen.

---

## 5. Layout Principles
- **Global Container Padding:** 24px horizontal. Konten tidak boleh menyentuh tepi layar.
- **Airy & Structured:** Jarak vertikal dijaga ketat menggunakan Grid System (kelipatan 8px).
- **Focal Point Minimalis:** Kontras diciptakan oleh tipografi (bold/regular) dan Ink Black pada elemen interaktif.
- **Left-Aligned Bias:** Semua teks rata kiri. Hanya tombol/aksi tertentu yang menyesuaikan lokasi.

---

## 6. Design Constraints (CONST)

- **CONST-01**: Palet warna monokromatik hangat — **Warm Off-White (`#FAF9F7`)** / **Ink Black (`#111111`)** / **Paper Gray (`#F0EFED`)**. TIDAK menggunakan pure white (`#FFFFFF`) atau pure black (`#000000`).
- **CONST-02**: Tipografi day headers: uppercase, extra-bold (800), tight letter-spacing. TIDAK menggunakan konsep *Mixed-Weight Headers*.
- **CONST-03**: **MODERATE BORDER RADIUS** (4px - 12px). Hindari kapsul penuh (999px), KECUALI FAB.
- **CONST-04**: **NO SHADOWS**. Kedalaman diciptakan melalui Paper Gray di atas Warm Off-White.

---

> [!NOTE]
> **Sinkronisasi Web:** Sejak web app masuk scope (lihat PRD.md Section 3.6), token warna di file ini juga jadi rujukan untuk `web/tailwind.config.ts` — pastikan nilai hex yang dipakai di Tailwind config disinkronkan ke sini, bukan sebaliknya.
