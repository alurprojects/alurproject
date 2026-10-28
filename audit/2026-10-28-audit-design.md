# Audit & Review Area Design — ALUR (2026-10-28)

**What this repo does:** ALUR = aplikasi planner pribadi (Flutter mobile + Next.js web + FastAPI backend) dengan AI companion. Area design yang diaudit: dua dokumen spec (`.agents/skills/read-docs/docs/DESIGN.md` untuk mobile, `DESIGN-WEB.md` untuk web) dan implementasinya (`mobile/lib/core/`, `web/tailwind.config.ts`, `web/app/globals.css`, komponen web).
**Load yang diasumsikan:** aplikasi personal 1 user, dark mode aktif di mobile — bukan produk multi-tenant.

**Bentukannya:** audit design = diff 3 lapis — (1) spec SSOT (DESIGN.md), (2) token platform (tailwind + AppColors), (3) pemakaian di layar/komponen. Temuan = setiap tempat lapisan tidak cocok.

---

## Must fix

1. **Satu aksen, tiga cerita** (`DESIGN.md §2+§4`, `mobile/lib/core/constants/app_colors.dart:L20-21,60`, `web/tailwind.config.ts:L19`)
   - **What this is:** Warna aksen aplikasi. DESIGN.md bilang Ink Black satu-satunya aksen kuat dan checkbox terisi Ink Black; invariant inti bilang Vermilion `#FF5420` hanya untuk task done; tailwind punya `alert: #C1502E` "Terracotta"; mobile alias `terracotta = orangeAccent (FF5420)`.
   - **Problem:** Nama sama, warna beda. `terracotta` di mobile = FF5420, `alert` di web = C1502E. Task done mobile = FF5420, menurut DESIGN.md §4 harusnya Ink Black.
   - **Fix:** Satu keputusan di DESIGN.md: tambahkan Vermilion `#FF5420` ke palet sebagai aksen "task done", perbaiki teks Task Row §4, hapus alias `terracotta`. Web: samakan makna `alert` (C1502E hanya untuk miss/error) dan tulis di DESIGN.md.
   - **If we skip it:** Dua platform memberi makna beda untuk warna yang namanya sama; kontributor baru menebak warna.

2. **Mobile jalan di dua palet sekaligus** (`mobile/lib/core/constants/app_colors.dart:L6-10,24-42,44-50`)
   - **What this is:** Palet kerja mobile: scaffold `#EDEBE7`, teks `#22201D`, cascade 7 hari `#EDEBE7→#AAA8A1` ("matte notebook"). Di file yang sama ada blok "Canonical ALUR Tokens (DESIGN.md)" `#FAF9F7/#1A1A1A/...` yang juga dipakai layar-layar.
   - **Problem:** `app_theme.dart` scaffold = `#EDEBE7`, tapi `calendar_screen.dart:L108` pakai `warmOffWhite (#FAF9F7)`; teks kadang `#22201D` kadang `#1A1A1A`. Dua bahasa visual dalam satu app — catatan NOTE di DESIGN.md ("sync dari sini") tidak terpenuhi.
   - **Fix:** Putuskan satu: kalau mockup acuan (`#EDEBE7` + cascade) yang benar, ubah DESIGN.md §2 dan jadikan palet AppColors satu sistem; kalau DESIGN.md yang benar, ganti nilai `lightBackground` dkk ke token kanonik. Sekali putus, hapus pasangan duplikat.
   - **If we skip it:** Seam warna antar layar (scaffold vs screen) terlihat di light mode, dan "Single Source of Truth" jadi klaim kosong.

3. **Dark mode tak berspesifikasi + melanggar CONST-01** (`mobile/lib/core/constants/app_colors.dart:L12-17`, `widgets/pill_button.dart:L32-38`)
   - **What this is:** Mobile punya tema gelap penuh (`#4A4947` bg, day shades gelap) tapi DESIGN.md tidak mendefinisikan palet dark sama sekali.
   - **Problem:** PRD menjadikan theme toggle fitur Profile; implementasi dark mengarang palet sendiri, dan `pill_button.dart` memakai `pureWhite`/`pureBlack` (`#FFFFFF/#000000`) yang melanggar CONST-01.
   - **Fix:** Tambahkan §"Dark Palette" di DESIGN.md (ambil nilai dari `app_colors.dart` sekarang sebagai baseline), lalu ganti `pureWhite`/`pureBlack` di pill_button dengan token dark yang didefinisikan (mis. `#F0EEEA`).
   - **If we skip it:** Dark mode "resmi" tapi tidak ada acuan — setiap layar baru menebak warna.

## Should fix

4. **Playfair Display dirujuk ke bagian yang tidak ada** (`web/app/globals.css:L19-23`, `web/app/layout.tsx:L20`, `web/app/components/AuthScreen.tsx:L128`)
   - **What this is:** Font serif display untuk headline auth, dikomentari sebagai "DESIGN-WEB.md §3.1".
   - **Problem:** DESIGN-WEB.md hanya punya §1–§2 (40 baris); tidak ada §3.1, tidak ada Playfair. Ini konflik dengan CONST-02 (Inter untuk semua judul).
   - **Fix:** Pilih satu: dokumentasikan pengecualian di DESIGN-WEB.md (buat §3.1 "Display Serif: Playfair Display, hero/auth saja"), atau hapus Playfair (1 class + 1 font link) dan pakai Inter 800. Dokumentasi lebih murah: keputusan sudah terlanjur dipakai.
   - **If we skip it:** Rujukan spec palsu menyesatkan reviewer berikutnya.

5. **Web: token ada, tapi komponen calendar tulis hex mentah** (`web/app/components/calendar/CalendarHeader.tsx:L7-32`, `CalendarToolbar.tsx`, `CalendarGrid.tsx:L21-47`)
   - **What this is:** `text-[#7A7772]`, `bg-[#F0EFED]`, `bg-[#111111]` — arbitrary values — padahal token `alur-warmgray`, `alur-surface`, `alur-ink` sudah didefinisikan di tailwind.config.ts dan dipakai komponen lain.
   - **Problem:** Ganti warna brand = edit 2 tempat; dua cara menulis warna yang sama dalam satu codebase.
   - **Fix:** Ganti semua arbitrary hex palette ke kelas `alur-*` (cari `[#` di `web/app/components/`). Murni find-replace.
   - **If we skip it:** Rebrand = audit manual puluhan file.

6. **Warna stabilo tidak terdefinisi di spec** (`web/app/components/calendar/EventCard.tsx:L15-16`)
   - **What this is:** Event calendar punya warna `#FCE181` (kuning), `#F9C3D6` (pink). DESIGN-WEB.md menyebut konsep "warna stabilo" tapi tidak pernah mendefinisikan hex-nya.
   - **Problem:** Palet kedua tanpa spesifikasi — tidak bisa dicek konsistensinya, tidak tahu daftar lengkapnya apa.
   - **Fix:** Tambahkan daftar warna stabilo (hex final) ke DESIGN-WEB.md, atau pindahkan ke tailwind token agar satu sumber.
   - **If we skip it:** Warna tumbuh liar tiap komponen baru.

7. **DESIGN-WEB.md stale: komponen hantu & link mati** (`.agents/skills/read-docs/docs/DESIGN-WEB.md:L34-40`)
   - **What this is:** Doc mendaftar `DayColumn.tsx`, `WeekGrid.tsx`, `SomedayDrawer.tsx` — ketiganya tidak ada di repo; yang ada `DayColumnInline` inline di `page.tsx:L529`. Semua link menunjuk ke `e:/Work-Learn/...` (path mesin lama). `BrainDumpModal.tsx` ternyata di `components/`, bukan `planner/`.
   - **Problem:** Pembaca baru mencari file yang tidak ada.
   - **Fix:** Update §2: hapus 3 komponen hantu, tulis `DayColumnInline (di page.tsx)`, ganti link ke path relatif `web/app/...`.
   - **If we skip it:** Doc SSOT merusak kepercayaan — orang berhenti percaya doc.

8. **Alias warna mati + warna hardcode** (`mobile/lib/core/constants/app_colors.dart:L52-61`)
   - **What this is:** Blok "Legacy & Compatibility Aliases": `terracotta`, `infoSlate`, `mediumGray`, `lightGray`, `checkedAccent` — nol pemakaiaan (sudah di-grep seluruh `mobile/lib`).
   - **Problem:** Kode mati yang mengklaim kompatibilitas; `checkedAccent` alias juga tak terpakai (screen pakai `orangeAccent` langsung). Di sisi lain ada 22 hardcode `Color(0xFF...)` di `mobile/lib/screens/` (contoh `main_screen.dart:L171` `#E8E6E1`) yang melewati AppColors.
   - **Fix:** Hapus 5 alias mati; untuk hardcode, angkat ke AppColors saat menyentuh file tersebut (bukan big-bang).
   - **If we skip it:** Alias menyesatkan (nama `terracotta` ≠ warna terracotta web) dan palet bocor.

## Nice to have

9. **Token `alur-info` mati** (`web/tailwind.config.ts:L20`, `app_colors.dart:L61`)
   - **Problem:** `#6B7280` didefinisikan dua platform, tak dipakai di keduanya.
   - **Fix:** Hapus keduanya. Kalau nanti butuh warna info, tambahkan waktu itu.
   - **If we skip it:** 2 baris mati + pertanyaan "ini buat apa" tiap audit.

10. **Letter-spacing heading web tidak persis spec** (`web/app/globals.css:L16`)
    - **Problem:** Spec DESIGN.md §3: -0.04em / -1.5px; globals pakai -0.03em, `tracking-tight` Tailwind = -0.025em. Beda halus, tidak terlihat kebanyakan orang.
    - **Fix:** Set `letter-spacing: -0.04em` di base heading. Satu baris.
    - **If we skip it:** Day header web sedikit lebih renggang dari mockup acuan.

---

**Verdict:** Kerangka design system sehat (token web lengkap, Inter konsisten, arsitektur tema Flutter rapi), tapi SSOT-nya bocor: mobile jalan di palet lain, dark mode & aksen vermilion belum tertulis, dan doc web stale. Fix 1–2 dulu.
**Lean: -12 baris kode mati (5 alias + 2 token), -1 dependensi font (jika Playfair di-drop).**
**Not checked:** build/runtime visual (tidak dirun), sinkronisasi bobot font via getComputedStyle, `web/app/page.tsx` penuh (900+ baris, hanya dicek pola warna & komponen), sketsa UI di `auth.md` vs `AuthScreen.tsx`, diagram `diagrams/` & `audit/` (deliverable sesi ini, bukan bagian produk).
