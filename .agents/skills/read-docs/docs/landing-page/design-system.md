# ALUR — Design System & UI Vibe (BakwanSpace Studio)

> **Tanggal:** 2026-10-08 | **Status:** Vibe-Coding Ready
> **Cakupan:** Landing Page & Web App Core
> **Fokus:** Warm minimalism, editorial typography, zero-elevation UI

## 1. Core Principles
- **Honest & Grounded:** Desain tidak boleh terlihat seperti dashboard SaaS yang riuh. Harus terasa seperti meja kerja fisik dengan kertas dan tinta.
- **Product by Studio Model:** Memancarkan kejelasan hierarki — ALUR sebagai produk utama, BakwanSpace sebagai kreator. Logo ALUR mendominasi, dengan identitas studio tampil halus sebagai *footer* dan *meta tag*.
- **Zero Elevation (CONST-04):** Sama sekali TIDAK menggunakan `box-shadow` atau gradien. Dimensi dicapai murni melalui layering warna solid (Paper Gray di atas Warm Off-White) dan border tipis 1px.
- **Typographic Hierarchy (CONST-02):** Kontras ukuran font yang ekstrem antara H1 (sangat besar, bold, uppercase) dan body text (regular, ukuran baca standar).

## 2. Color Palette (Tokens)

Menggunakan palet monokromatik hangat. Jangan gunakan warna putih murni (`#FFFFFF`) untuk background, atau hitam murni (`#000000`) untuk teks.

| Token | Hex | Tailwind Class | Penggunaan |
| :--- | :--- | :--- | :--- |
| `bg-primary` | `#FAF9F7` | `bg-[#FAF9F7]` | Canvas utama (body background). Warm Off-White. |
| `bg-surface` | `#F0EFED` | `bg-[#F0EFED]` | Latar belakang card, container sekunder. Paper Gray. |
| `text-primary` | `#1A1A1A` | `text-[#1A1A1A]` | Teks utama, judul, body copy utama. Charcoal. |
| `text-secondary`| `#7A7772` | `text-[#7A7772]` | Sub-judul, placeholder, teks meta, kredit studio. Warm Gray. |
| `border-line` | `#DEDBD6` | `border-[#DEDBD6]` | Garis pemisah tipis 1px. Hairline Gray. |
| `accent-dark` | `#111111` | `bg-[#111111]` | Tombol utama, active state, checkbox checked. Ink Black. |
| `accent-light`| `#FFFFFF` | `text-white` | Teks di atas `accent-dark`. True White (hanya untuk teks). |

### Tailwind Config (Vibe-Coding Setup)
```javascript
theme: {
  extend: {
    colors: {
      alur: {
        'off-white': '#FAF9F7',
        'paper': '#F0EFED',
        'charcoal': '#1A1A1A',
        'warm-gray': '#7A7772',
        'hairline': '#DEDBD6',
        'ink': '#111111',
      }
    },
    fontFamily: {
      sans: ['Inter', 'sans-serif'],
    }
  }
}
```

## 3. Typography Scale (Inter Font Family)

Semua teks menggunakan font **Inter**.

| Elemen | Weight | Size | Line Height | Letter Spacing | Text Transform | Tailwind Classes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **H1 (Hero)** | Black (900) | 48px-64px | 1.05 | -0.04em | UPPERCASE | `font-black text-5xl md:text-6xl leading-[1.05] tracking-[-0.04em] uppercase` |
| **H2 (Section)**| Extra-Bold (800) | 24px-32px | 1.2 | -0.03em | UPPERCASE | `font-extrabold text-2xl md:text-3xl leading-snug tracking-[-0.03em] uppercase` |
| **H3 (Card)** | Bold (700) | 18px-20px | 1.3 | -0.01em | Normal | `font-bold text-lg md:text-xl leading-tight tracking-[-0.01em]` |
| **Body text** | Regular (400) | 16px | 1.6 | Normal | Normal | `font-normal text-base leading-relaxed` |
| **Small text** | Regular (400) | 14px | 1.5 | Normal | Normal | `font-normal text-sm leading-normal text-alur-warm-gray` |
| **Micro copy / Studio Credit** | Regular (400) | 12px | 1.4 | Normal | Normal | `font-normal text-xs leading-none text-alur-warm-gray` |
| **Button CTA** | Semi-Bold (600) | 16px | 1.0 | Normal | Normal | `font-semibold text-base` |

## 4. Spacing & Layout (8pt Grid)

- Semua margin dan padding **harus kelipatan 4px atau 8px**.
- **Micro spacing:** 4px, 8px, 12px (untuk jarak antar teks dengan ikon, dll)
- **Component spacing:** 16px, 24px, 32px (padding dalam card, tombol)
- **Section spacing:** 64px, 80px, 120px (jarak vertikal antar area konten)
- **Max Content Width:** 1120px (`max-w-6xl mx-auto`) dengan padding horizontal `px-6` (mobile) hingga `md:px-12`.

## 5. Bentuk (Border Radius)

- Menggunakan kelengkungan moderat (*Moderate Border Radius* - CONST-03).
- **Cards & Buttons:** `rounded-lg` (8px) atau `rounded-xl` (12px).
- **Input Fields:** `rounded-md` (6px) atau `rounded-lg` (8px).
- Hindari bentuk *pill* (`rounded-full`), kecuali untuk Floating Action Button (FAB) atau tag kecil.

## 6. Motion & Interactivity

- **Tombol Utama:** Transisi opacity saat di-hover. `transition-opacity duration-200 hover:opacity-85`.
- **Card Hover:** *TIDAK ADA EFEK ELEVASI (NO SHADOW ON HOVER).* Jika perlu interaksi, gunakan perubahan warna border atau sedikit pergeseran latar belakang dari `bg-alur-paper` ke warna sedikit lebih gelap.
- Fokus pada *purposeful motion*, hindari animasi melayang atau berayun.
