# Design System: ALUR

**Visi Desain:** Tenang, lapang, dan minimalis fungsional di atas kanvas gelap. ALUR memakai **dark editorial**: latar hitam pekat, kartu sedikit lebih terang, teks off-white kontras tinggi, tipografi display super tebal, dan **satu** aksen vermilion yang menyala. Identitas utamanya ada pada whitespace, hierarki tipografi, dan garis hairline — bukan dekorasi.

---

## 1. Visual Theme & Atmosphere

Kanvas gelap seperti kertas hitam di ruang kerja malam: matte, tanpa bayangan, tanpa gradasi, tanpa glow. Kontras dibangun dari tiga lapis permukaan (background → surface → surface-raised) dan satu aksen. Kesan yang dituju: fokus, tenang, tegas — bukan dashboard SaaS, bukan neo-brutalism.

- **Mode utama:** dark (default aplikasi).
- **Mode sekunder:** light, memakai peran token yang sama (lihat tabel mapping §2).
- **Flat:** TIDAK ada `box-shadow`, gradient, atau glow.

---

## 2. Color Palette & Roles

### Token kanonik (dark — default)

| Token | Hex | Peran |
| :--- | :--- | :--- |
| `bg` | `#0A0A0A` | Background aplikasi. |
| `surface` | `#161616` | Kartu, sheet, day-strip non-aktif, bubble AI. |
| `surface-raised` | `#1F1F1F` | Elemen di atas surface: bubble user, chip terpilih, row hover/pressed. |
| `text` | `#F5F4F1` | Teks utama, judul, task title. |
| `text-muted` | `#8F8B84` | Meta, label mono, placeholder, task selesai. |
| `hairline` | `rgba(255,255,255,0.10)` | Border 1px, divider, outline checkbox idle. |
| `accent` | `#FF5420` | Vermilion. Satu-satunya warna. |

### Mapping light (mode sekunder, peran sama)

| Token | Hex |
| :--- | :--- |
| `bg` | `#FAF9F7` |
| `surface` | `#F0EFED` |
| `surface-raised` | `#F7F6F3` |
| `text` | `#111111` |
| `text-muted` | `#7A7772` |
| `hairline` | `#DEDBD6` |
| `accent` | `#FF5420` |

### Aturan aksen (ketat)

- `accent` hanya untuk: **FAB**, **tab aktif**, **centang task selesai**, **peringatan overload** (garis kapasitas saat melebihi), **satu frasa penekanan per layar**.
- Maksimal **satu blok aksen besar per layar**. Aksen tidak pernah jadi latar section.
- Teks/ikon di atas `accent` memakai `#0A0A0A` (kontras 6.1:1). **Jangan** pakai putih di atas aksen (3.3:1 — gagal WCAG AA).
- Aksen tidak dipakai untuk border dekoratif, ikon nav non-aktif, atau chart.

---

## 3. Typography Rules

Tipografi editorial bervolume tinggi (*high-contrast geometric neo-grotesque*) berbasis **Inter**:

- **Day Header (H1 / Display):** Inter **Black (900)**, uppercase, `letter-spacing: -0.04em`, 48px mobile / 32px web. Warna `text`.
- **Section Header (H2/H3) & modal title:** Inter **Bold (700)**, 16–20px, `text`, line-height 24px.
- **Body / Task title:** Inter **Medium (500)** 16px mobile (14px web), `text`, line-height 24px / 20px.
- **Meta / label mono:** Inter **Regular (400)** 10–12px, uppercase, `letter-spacing: 0.08em`, `text-muted`. Angka memakai `font-variant-numeric: tabular-nums`.
- **Button / action:** Inter **Semi-Bold (600)**, tracking normal.

*Bukan* font rounded/condensed (Barlow dsb). Tidak ada *mixed-weight header*.

### Spacing (8pt grid)
- **Micro (4–8px):** ikon↔teks, judul↔meta.
- **Component (16–24px):** padding kartu/row, jarak antar task.
- **Section (32–48px):** pemisah blok utama.

---

## 4. Component Stylings

### Day Header (aktif)
Inter Black 900 uppercase, 48px mobile, `text`. Latar `bg` — header bukan kartu. Meta di bawahnya: baris mono `28 OKT · 4 TUGAS · 2 JAM 15 MENIT`.

### Day Strip (tampilan mingguan — bukan Home)
Strip horizontal 7 hari untuk tampilan mingguan; **tidak ada di Home** (Home fokus satu hari & Morning Brief, akses minggu melalui tab To Do List / toggle Weekly Overview). Hari aktif: label `text` + underline `accent` 2px; hari lain `text-muted`, tanpa latar.

### Task Row
- **Checkbox:** kotak 18px, `border-radius: 4px`, border 1px `hairline`. Selesai → latar `accent`, ikon centang `#0A0A0A`, tanpa border.
- **Task title:** 16px Medium `text`; selesai → `text-muted` + strikethrough.
- **Meta:** mono 10–11px `text-muted` (`45 MNT · 09:00`).
- **Chip `?`:** pill outline `hairline`, teks mono `text-muted` — hanya untuk durasi/waktu ambigu.
- **Divider:** 1px `hairline` antar row. Tanpa border luar.
- **Swipe:** geser kiri → pindah hari / hapus.

### Follow-up / Reschedule Chip
Pill outline `hairline`, teks mono `text-muted`: `1 TUGAS DITUNDA · TANYA LAGI?`. Muncul hanya saat `missed_follow_up = PENDING`.

### Buttons
- **Primary (satu-satunya):** FAB lingkaran 56px, latar `accent`, ikon `+` `#0A0A0A`. Tidak ada CTA sekunder berbobot sama.
- **Secondary / ghost:** teks `text-muted` atau outline `hairline`, latar transparan. Termasuk ghost row `+ TAMBAH TUGAS`.
- **Destruktif:** teks `#FF5420`, latar transparan, selalu butuh konfirmasi.

### Cards & Grouping
- **Card:** latar `surface`, border 1px `hairline`, radius 12px, padding 16–20px, tanpa shadow.
- **Section separation:** whitespace + hairline, bukan kotak bertumpuk.

### Chat Room
- **Bubble user:** `surface-raised`, teks `text`, radius 8px, tanpa border.
- **Bubble AI:** `surface` + border `hairline`, teks `text`.
- **Input area:** `surface`, border `hairline`, menempel bawah, di atas keyboard.

### Bottom Navigation (3 tab) & Top-Right Profile
Bottom Navigation menu mobile secara eksklusif hanya memuat 3 tab: **Home** · **To Do List** · **Chat**.
- Label mono 10px uppercase.
- **Aktif:** ikon `accent` + label `text` + dot 4px `accent`.
- **Non-aktif:** ikon & label `text-muted`. Border atas 1px `hairline`.
- **Calendar:** Status *on-hold* (ditunda dari tab bar mobile v1).
- **Profile (Top-Right Action):** Dipindahkan dari tab bar ke pojok kanan atas header (Top App Bar). Berupa ikon avatar/lingkaran minimalis (diameter 32–36px, border 1px `hairline`, latar `surface`), membuka sheet/layar Profile saat di-tap.

### Illustrations & Imagery
Line-art satu warna: stroke `#F5F4F1` pada 60% opacity, satu bidang `accent` maksimal. Tanpa ilustrasi dekoratif di dalam list.

---

## 5. Layout Principles
- **Global padding:** 20–24px horizontal. Konten tidak menyentuh tepi layar.
- **Airy & structured:** jarak vertikal kelipatan 8px.
- **Focal point:** tipografi (900 vs 400) dan satu aksen — bukan warna-warni.
- **Left-aligned bias:** semua teks rata kiri; hanya ikon aksi yang rata kanan.

---

## 6. Design Constraints (CONST)

- **CONST-01**: Palet kanonik = token §2. Dark adalah default. Dilarang pure black `#000000` / pure white `#FFFFFF` sebagai latar atau teks.
- **CONST-02**: Tipografi Inter. Day header uppercase Black 900, `-0.04em`. Body Medium 500. Dilarang font narrow/rounded dan mixed-weight header.
- **CONST-03**: Border radius 4–12px. Kapsul penuh (999px) hanya untuk FAB dan pill chip.
- **CONST-04**: **NO SHADOWS & NO GRADIENTS.** Kedalaman dari tiga lapis surface + hairline.
- **CONST-05**: Satu aksen per layar. Teks di atas aksen selalu `#0A0A0A`.
- **CONST-06**: Setiap layar wajib punya state: kosong, loading, error/offline (line-art + satu kalimat + jalan keluar).
- **CONST-07**: Tidak ada dashboard, chart, gamifikasi (streak/badge/ring), atau widget dekoratif.

---

## 7. Motion & Transition System

Prinsip *quiet, purposeful motion* — hanya untuk kejelasan spasial dan umpan balik.

### A. Auth Transitions
- **Login (`AuthScreen` → `MainScreen`)**: 350ms, `cubic-bezier(0.4, 0.0, 0.2, 1)`, fade 0→1 + scale 0.98→1.00.
- **Logout (`MainScreen` → `AuthScreen`)**: 250ms, `easeOutCubic`, fade out-in.

### B. Tab Transitions
- **State preservation:** `IndexedStack` (atau setara) — scroll, input, dan state tiap tab dipertahankan.
- **Switching:** instan (0ms), ikon langsung berubah ke `accent`.

### C. Micro-feedback
- Centang task: 150ms, opacity + scale 0.9→1.0. Tanpa bounce.
- Tidak ada animasi loop, parallax, atau shimmer warna. Skeleton loading = blok `surface` flat.

---

## 8. Web Scope (ringkas)

Web memakai token §2 yang sama, layout berbeda: **weekly notebook** — 7 kolom hari, satu kartu penuh per task (`w-full`, radius 8–12px, hairline), edit lewat modal kontras tinggi (surface-raised, teks `text`). Checkbox di kiri kartu, meta mono di bawah judul. Tidak ada dashboard, chart, atau panel statistik. Komponen yang benar-benar ada: `PlannerHeader`, `TaskItem`, `TaskEditModal`, `GoalPanel`, `CalendarGrid`. DayColumn/WeekGrid/SomedayDrawer tidak ada — jangan dirujuk.

---

> [!NOTE]
> **Sinkronisasi Multi-Platform:** Token §2 dan aturan tipografi §3 adalah Single Source of Truth untuk Web (`web/tailwind.config.ts`, `web/app/globals.css`) dan Mobile Flutter (`mobile/lib/core/theme/app_theme.dart`). Setiap hex baru wajib masuk tabel §2 lebih dulu.

<!-- ryux-context:start -->
- **UI direction**: dark editorial minimalis — bg `#0A0A0A`, surface `#161616`, surface-raised `#1F1F1F`, text `#F5F4F1`, muted `#8F8B84`, hairline `rgba(255,255,255,0.10)`, satu aksen vermilion `#FF5420` (FAB, tab aktif, centang selesai, satu frasa per layar). Flat tanpa shadow/gradient/glow. Inter 900 uppercase day header, Inter 400 mono meta. Light mode = mapping peran yang sama. Bukan dashboard, bukan gamifikasi, bukan neo-brutalism.
<!-- ryux-context:end -->

## Changelog
- **v3 (2026-10-28)** — Audit & Revisi Navigasi Mobile: Tab menu bawah dipangkas menjadi 3 tab (Home, To Do List, Chat). Calendar di-hold dari bottom bar mobile v1. Profile dipindahkan ke pojok kanan atas (Top-Right Action).
- **v2 (2026-10-28)** — Arah gaya diganti ke dark editorial (mengikuti referensi user). Palet light lama jadi mode sekunder; token dark jadi kanonik. Checkbox bulat → kotak 4px, FAB ink → vermilion, tambah CONST-05/06/07 (aksen, state wajib, larangan dashboard).
- **v1 (2026-09-28)** — Warm Monochrome Editorial (paper/ink/hairline).
