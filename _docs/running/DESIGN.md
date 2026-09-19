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

ALUR menggunakan tipografi editorial bervolume tinggi (*high-contrast geometric neo-grotesque*) berbasis keluarga font **Inter**:
- **Title Style & Day Headers (H1 / Display):** **Inter** dengan bobot **Black (900)** atau **Extra-Bold (800)**, uppercase, dan tight letter-spacing (-1.5px / -0.04em). Menghasilkan kesan *bold, solid, authoritative, and tactile editorial* persis seperti mockup acuan (`TUESDAY`, `WEDNESDAY`, dsb). *Bukan* font rounded/condensed seperti Barlow.
- **Section Headers (H2 / H3) & Modal Titles:** **Inter Bold (700)** / **Extra-Bold (800)**, ukuran 16px - 20px, Charcoal.
  - **Line-height:** 24px. Margin bawah: 16px.
- **Body Text / Task Text:** **Inter Regular (400)** / **Medium (500)**, ukuran 14px, Charcoal.
  - **Line-height:** 20px.
- **Muted/Meta Text:** **Inter Regular (400)**, ukuran 12px, Warm Gray.
  - **Line-height:** 16px.
- **Buttons / Actions:** **Inter Semi-Bold (600)** / **Bold (700)**, clean tracking.

### Spacing Principles (The 8pt Grid System)
Semua jarak, margin, dan padding **harus merupakan kelipatan dari 4px atau 8px**.
- **Micro spacing (4px - 8px):** Jarak antara teks tugas dan ikon, antara judul dan deskripsi kecil.
- **Component spacing (16px - 24px):** Jarak antar tugas dalam satu list, padding dalam tombol/card.
- **Section spacing (32px - 48px):** Whitespace besar untuk memisahkan antar blok konten utama.

---

## 4. Component Stylings

### Day Header (Active/Expanded)
Header hari aktif ditampilkan dengan font **Inter Black (900)** / **Extra-Bold (800)**, uppercase, tight letter-spacing (-1.5px), berukuran besar (48px pada mobile, 24px-32px pada web). Background menggunakan Warm Off-White. Tidak menggunakan warna solid Ink Black sebagai latar — Ink Black hanya untuk interaksi.

### Day Strip (Collapsed)
Hari yang tidak aktif ditampilkan sebagai strip horizontal minimalis dengan latar **Paper Gray (`#F0EFED`)**. Teks hari menggunakan font **Inter Black (900)** / **Extra-Bold (800)**, uppercase, tight letter-spacing (-1.5px), vertically centered.

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
- **CONST-02**: Tipografi title & day headers: WAJIB menggunakan font **Inter**, uppercase, Black (900) atau Extra-Bold (800), tight letter-spacing (-1.5px / -0.04em). Body & meta text menggunakan font **Inter** (Regular 400). TIDAK menggunakan font narrow/rounded (seperti Barlow) dan TIDAK menggunakan konsep *Mixed-Weight Headers*.
- **CONST-03**: **MODERATE BORDER RADIUS** (4px - 12px). Hindari kapsul penuh (999px), KECUALI FAB.
- **CONST-04**: **NO SHADOWS**. Kedalaman diciptakan melalui Paper Gray di atas Warm Off-White.

---

## 7. Motion & Transition System

ALUR memegang teguh prinsip *quiet, purposeful motion*. Animasi hanya digunakan untuk memberikan kejelasan spasial dan umpan balik fungsional, bukan hiburan visual (*no bouncy, slow, or distracting flourishes*).

### A. Auth Transitions (Login & Logout)
- **Login Transition (`AuthScreen` → `MainScreen`)**:
  - **Durasi**: **350ms**
  - **Kurva (*Easing*)**: `Curves.easeInOutCubic` (atau `cubic-bezier(0.4, 0.0, 0.2, 1)`)
  - **Efek**: Kombinasi *Fade-in* (0.0 → 1.0) dengan *Subtle Scale Lift* (0.98 → 1.00). Memberi sensasi kanvas kerja yang terangkat lembut ke hadapan pengguna.
- **Logout Transition (`MainScreen` → `AuthScreen`)**:
  - **Durasi**: **250ms**
  - **Kurva (*Easing*)**: `Curves.easeOutCubic`
  - **Efek**: *Clean Fade Out-In* (Opacity 1.0 → 0.0) langsung ke landing `AuthScreen` untuk transisi pembersihan yang cepat dan privat.

### B. Tab Transitions (4-Tab Bottom Navigation)
- **State Preservation**: Wajib menggunakan `IndexedStack` (atau setara) agar setiap tab mempertahankan posisi *scroll*, data input, dan status komponen saat pengguna berpindah tab.
- **Switching Speed**: **Instant (0ms latency)** untuk navigasi tab, dengan perubahan langsung pada ikon navigasi (outline menjadi solid Ink Black) dan label berbobot tebal (`FontWeight.w700`).

---

> [!NOTE]
> **Sinkronisasi Multi-Platform:** Token warna dan konfigurasi tipografi (Inter Black 900 / ExtraBold 800 untuk Title Style & Headers, Inter Regular 400 untuk Body & Meta) di file ini adalah Single Source of Truth untuk implementasi di Web (`web/tailwind.config.ts`, `web/app/globals.css`) dan Mobile Flutter (`mobile/lib/core/theme/app_theme.dart`). Pastikan bobot font dan letter-spacing disinkronkan dari sini ke seluruh platform.
