# DESIGN-WEB.md — Arah Desain Web ALUR (adopsi referensi waitlist doodle-grid)

> Status: direction dari user + audit RYUX. Spesifikasi inti tetap di
> `.agents/skills/read-docs/docs/DESIGN.md` (Single Source of Truth token & konstrain).
> File ini mencatat ADOPSI gaya referensi untuk permukaan web ekspresif (landing/waitlist/auth).

## 1. Sumber

- **Referensi**: gambar mockup waitlist yang disematkan user (provenance: `sourced`, dari user —
  BUKAN screen produk nyata, BUKAN evidence pasar). Semua klaim visual di bawah bertipe
  `{ observed, user-mockup }`, bukan `{ knowledge, ryux-knowledge }`.
- **MCP RYUX**: terkoneksi. `search_screens` / `extract_design_direction` hanya mengembalikan
  data sample (`scr_demo_001` checkout, `scr_demo_002` OTP) — TIDAK relevan untuk waitlist.
  Evidence MCP untuk keputusan ini: **None**. Keputusan di bawah berbasis arahan user
  (input, bukan saran) + `docs/DESIGN.md` + audit tool.

## 2. Audit referensi (Observed)

### 2.1 Tipografi
- **Display**: serif bold high-contrast (gaya Didone/transitional, mis. karakter `J`/`w` di
  "Join our waitlist") — ukuran besar, centered, sentence case. Titik fokal emosional.
- **Body**: sans netral ~14px, centered, measure pendek (~60ch).
- **Label/CTA**: sans kecil uppercase dengan tracking lebar (`GET EARLY ACCESS`, tag
  `Email Address` menempel di tepi atas field). Microcopy kanan (`Steak dish` + bintang +
  meta 10px).
- **Audit MCP `audit_copy`: FAIL** — 1 error: body `Lorem ipsum...` = filler/placeholder
  (Hard Gate bila dikapalkan); 1 warning: button all-caps (hindari, pakai sentence case
  atau small-caps dengan tracking).

### 2.2 Layout
- Kartu hero centered, satu kolom, max-width sedang; alur baca: eyebrow/doodle →
  headline → subcopy → form → ilustrasi.
- Form = SATU baris: field email gelap (ink fill, teks putih, underline pada value) +
  tombol terang di kanan. Tepat 1 primary action (`audit_ui` R-04 PASS).
- Rel kanan: kartu konteks kecil (ikon + aksi + nama + rating + meta) — di referensi berisi
  konten food (`Steak dish`); untuk ALUR diganti konten produk (mis. status/testimoni) atau
  dibuang bila tanpa tujuan (purpose gate RX-AS-05).
- Elemen barcode kiri-atas: dekoratif, tanpa fungsi — JANGAN diadopsi kecuali lolos
  purpose gate (purpose, contribution, necessity).
- Ilustrasi strip bawah: jajaran figur line-art (inklusif: pengguna kursi roda, pesepeda),
  full-bleed di dalam kartu, sebagai penutup komposisi.

### 2.3 Sketsa / ilustrasi
- Line-art monokrom hitam-putih, stroke ~2px, gaya hand-drawn (doodle): figur manusia,
  ikon tangan, bingkai kolase foto-sketsa makanan di sekeliling kartu.
- Selaras dengan `docs/DESIGN.md:89-90` (line-art monokrom, fill Charcoal/Ink) — ADOPSI PENUH.

### 2.4 Background garis-garis (permintaan user)
- Kartu memakai **kertas grid/graph** (garis abu sangat terang, ~8–16px) + bingkai luar
  berupa kolase doodle. Grid = tekstur kertas kerja, bukan dekorasi warna.
- `audit_ui`: kontras teks ~10:1 PASS, target sentuh ~48px PASS, teks body 14px PASS.
  FAIL: state hanya `default` (wajib tambah loading/error/success) + tanpa touch feedback.

## 3. Arah yang diadopsi untuk Web ALUR

### 3.1 Token baru (hanya untuk permukaan ekspresif)
- `--alur-grid-line: #E9E6E1` — garis grid di atas `--alur-bg #FAF9F7`. Rasio grid 8px
  (selaras 8pt grid system). Opacity garis ≤ 1px solid, bukan gradient.
- Display font ekspresif: serif high-contrast (mis. Playfair Display / setara), HANYA untuk
  headline hero/landing/auth. Body, label, dan SEMUA task UI tetap Inter (CONST-02 berlaku).
- Aksen micro (bintang/rating): kuning hangat `#E3A008` — satu-satunya aksen non-mono,
  dipakai hemat.

### 3.2 Komponen
- **HeroCard**: kartu centered max-w ~880px, bg grid-paper, radius 12px, NO shadow
  (CONST-04 tetap).
- **EmailRow**: field ink `#111111` (teks putih, radius 0–4px) + tombol paper/putih
  ber-border hairline, label-tag kecil menempel di tepi atas field. Copy tombol sentence
  case (`Get early access`), bukan all-caps (temuan audit C-02).
- **PeopleStrip**: ilustrasi line-art figur (reuse gaya login illo), full-bleed bawah kartu.
- **ContextCard** (opsional): rel/slot kecil untuk bukti (status produk/testimoni) —
  unconfirmed, wajib purpose gate sebelum dipakai.
- Barcode dekoratif: TIDAK diadopsi (gagal purpose gate).

### 3.3 Copy
- DILARANG lorem ipsum di kanvas final (temuan audit C-01). Subcopy ditulis dari PRD
  (value prop ALUR), maks ~140 karakter, tone calm.

### 3.4 Motion
- Tetap quiet per `docs/DESIGN.md:111-123`: fade 250–350ms `easeInOutCubic`; form success =
 Centang + pesan, tanpa confetti/bounce.

### 3.5 Responsif
- ≥1024px: layout referensi penuh (form sebaris, context card kanan).
- 640–1023px: context card pindah ke bawah form atau disembunyikan; people strip menyusut.
- <640px: form menumpuk (field penuh → tombol penuh di bawah), headline serif mengecil
  proporsional, grid tetap.

## 4. Decision Receipts

```
Decision     Serif display hanya untuk headline permukaan ekspresif; task UI tetap Inter
Options      A Inter semua (status quo CONST-02) / B serif di mana-mana / C serif khusus hero+landing+auth
Evidence     None (MCP sample tidak relevan) + arahan user (input) + RX-UI-12 (expressive surface POV)
Confidence   Medium
Why          Karakter "calm editorial hangat" dari doodle-grid butuh display berwatak; Inter tetap untuk keterbacaan tugas
Trade-off    Dua keluarga font; beban ±30–60KB + aturan pemakaian ketat agar tidak bocor ke task UI
Assumption   Serif dipakai ≤3 ukuran display dan tidak untuk body/label
```

```
Decision     Background kertas grid 8px (#E9E6E1 di atas #FAF9F7) untuk hero/landing
Options      A polos off-white (status quo) / B grid 8px / C dot-grid
Evidence     Observed user-mockup (grid halus, kontras teks tetap ≥10:1) + audit_ui PASS R-01..R-04
Confidence   Medium
Why          Memperkuat metafora "matte paper workspace" tanpa shadow/gradient (CONST-04 tetap dipatuhi)
Trade-off    Tekstur baru; wajib jaga kontras AA bila grid dipakai di belakang teks
Assumption   Grid 1px solid, bukan gambar; bisa dimatikan via token
```

```
Decision     Form email gelap + CTA terang sebaris (1 primary action)
Options      A tombol ink + field terang (standar ALUR) / B field ink + tombol terang (referensi) / C keduanya terang
Evidence     Observed user-mockup + audit_ui R-04 PASS (1 CTA)
Confidence   Medium
Why          Field gelap memberi bobot "diisi di sini"; CTA terang menjaga Ink Black tetap untuk aksi primer saat submit
Trade-off    Menyimpang dari pola tombol-primary-ink; didokumentasikan sebagai varian hero saja
Assumption   Comportment submit/error mengikuti pola AuthScreen (spinner, role=alert)
```

## 5. Konflik dengan `docs/DESIGN.md` (perlu amandemen sadar)

- **CONST-02** (Inter-only): diamandemen TERBATAS — serif hanya headline ekspresif (§3.1).
  Task UI tidak berubah.
- **CONST-01/04**: tetap — tidak ada warna baru selain garis grid + micro-aksen; tanpa shadow.
- **Hard Gate copy**: subcopy final dilarang lorem ipsum; CTA hindari all-caps.

## 6. Asumsi & Unconfirmed

- Design assumption: grid 8px `#E9E6E1`, serif = Playfair Display (atau setara), dapat diganti
  saat implementasi tanpa mengubah arah.
- Unconfirmed: ContextCard kanan (butuh konten bukti nyata), link Terms di footer form.
- Sample data: email contoh di mockup adalah ilustrasi, bukan data nyata.

## Changelog
- 2026-10-14: dibuat dari audit referensi waitlist + MCP RYUX (search/direction/audit_ui/audit_copy).
- 2026-10-14: `/login` disesuaikan — HeroCard grid 24px (kelipatan 8), headline `.font-display`
  (Playfair Display via Google Fonts, `layout.tsx` + `globals.css`), PeopleStrip line-art,
  SSO Google tetap 1 CTA Ink. Grid 24px asumsi desain (mockup ~20–30px, tetap kelipatan 8pt).
  ContextCard tidak dipakai (unconfirmed). Logic OAuth tak tersentuh.
