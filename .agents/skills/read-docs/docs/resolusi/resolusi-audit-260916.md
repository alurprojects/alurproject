# resolusi-audit-260916.md

**Tujuan**: Menindaklanjuti 3 keputusan dari audit sebelumnya menjadi instruksi atomik yang bisa dieksekusi ke `PRD.md`, `DESIGN.md`, `technical.md`, `DEPLOYMENT_GUIDE.md`. Format sama seperti `rebuild-260916.md`.

**Cara pakai**: Tiap TASK berisi `File`, `Action`, `Location`, `Change`. Eksekusi berurutan per masalah.

---

## Governing Constraints (Hasil Keputusan Sesi Ini)

- CONST-08: Web app **resmi masuk scope** — bukan lagi Non-Goal. Tapi dibangun bertahap, **bukan full parity** dengan mobile sejak hari pertama (lihat Masalah 1).
- CONST-09: Arah produk dipertajam jadi **1 jiwa: "Realistic Planner — Honest Capacity"** (Opsi 2 dari sesi sparring). Ini menggantikan campuran 3 opsi yang ada di draf PRD sebelumnya.
- CONST-10: Palet warna kanon adalah **Warm Off-White (`#FAF9F7`)** / **Ink Black (`#111111`)** — versi lama, BUKAN pure white/black (`#FFFFFF`/`#000000`) dari draf `DESIGN.md` terbaru.
- CONST-11 (temuan baru saat menyelesaikan Masalah 2 — lihat penjelasan di sana): Mempertajam arah ke Opsi 2 **TIDAK mengharuskan** day-strip/accordion dibongkar. Izin untuk pivot UI tetap berlaku kalau ke depan dibutuhkan, tapi untuk resolusi ini day-strip **dipertahankan**, cuma dikembalikan ke desain lama (CONST-10), bukan dihapus.

---

## Masalah 1: Web App — Scope Bertabrakan dengan Non-Goals

**Masalah**: `PRD.md` Section 8 menyebut "web dashboard terpisah" sebagai Non-Goal, tapi `technical.md` & `DEPLOYMENT_GUIDE.md` sudah membangun Next.js penuh. Kalau web app dikonfirmasi masuk scope, kontradiksi ini harus dibereskan — TAPI jangan langsung full parity 4-tab sejak awal, itu menggandakan permukaan kerja (2 frontend sekaligus) sebelum mobile tervalidasi.

**Solusi**: Web app masuk sebagai scope resmi, dengan **scope awal dipersempit** — cuma To-do (Hybrid Daily/Weekly) + Calendar (read-only). Chat Room & Profile ditunda ke web sampai versi mobile-nya stabil (alasan: Chat Room baru saja dipertajam ulang di Masalah 2 — jangan bangun 2x di 2 platform sebelum bentuk finalnya terbukti).

**TASK-W01**
- File: `PRD.md`
- Action: MODIFY
- Location: Section 8 (Non-Goals)
- Change: Hapus baris "web dashboard terpisah". Ganti dengan: "Web app scope awal dibatasi ke To-do + Calendar (read-only); Chat Room & Profile di web ditunda sampai versi mobile stabil"

**TASK-W02**
- File: `PRD.md`
- Action: ADD
- Location: Setelah Section 3 (UI/UX Spec)
- Change: Tambah subsection "3.6 Web App — Scope Terbatas":
  ```
  Web app v1 HANYA berisi:
  - To-do (Hybrid Daily/Weekly, sama seperti mobile Section 3.2)
  - Calendar (read-only, sama seperti mobile Section 3.4)
  TIDAK ada Chat Room atau Profile di web v1. User yang mau brain-dump/chat
  tetap harus buka mobile. Ini keputusan sadar untuk membatasi permukaan
  kerja, bukan keterbatasan teknis.
  ```

**TASK-W03**
- File: `technical.md`
- Action: MODIFY
- Location: Section 3 (Struktur Repo), folder `web/app/`
- Change: Hapus referensi ke komponen chat di web (jika ada), pastikan struktur cuma berisi To-do & Calendar components

**TASK-W04**
- File: `DEPLOYMENT_GUIDE.md`
- Action: MODIFY
- Location: Section 3.1 (Struktur Direktori Web)
- Change: Update komentar `page.tsx` dari "Weekly view utama (7-day accordion)" jadi "Hybrid Daily/Weekly view (sinkron dengan PRD.md Section 3.2)" — supaya tidak stale terhadap keputusan UI mobile terbaru

---

## Masalah 2: Arah Produk Bercampur 3 Opsi — Perlu 1 Jiwa

**Masalah**: `PRD.md` Section 9 (Key Differentiators) mencampur elemen dari ketiga opsi sparring (Second Brain / Realistic Planner / Identity Loop) sekaligus. Positioning statement di Section 1 sebenarnya sudah condong ke Opsi 2 ("secara aktif jujur tentang kapasitas kamu") — jadi resolusi ini mengunci itu sebagai satu-satunya jiwa, dan memangkas elemen yang cuma numpang dari opsi lain.

**Temuan tambahan saat menyelesaikan ini**: Mempertajam ke Opsi 2 ternyata **tidak butuh membongkar day-strip/accordion**. Kekuatan Opsi 2 ada di Companion Agent & Insight, bukan di struktur To-do list. Jadi izin "pivot kalau day-strip mengganggu" tidak perlu dipakai untuk resolusi kali ini — day-strip dipertahankan, cuma warnanya dikembalikan (lihat Masalah 3).

**Solusi**: Pangkas sistem "Adaptive Personality" dari 4 tone jadi 2 tone yang jelas melayani misi kejujuran (bukan chatbot ramah-ramahan generik), dan reframe Chat Room supaya bukan dijual sebagai "capture semua hal" (itu bahasa Opsi 1) tapi sebagai ruang cek realita kapasitas.

**TASK-D01** (penamaan disambung dari `PRD.md`, bukan `DESIGN.md` — lihat konteks)
- File: `PRD.md`
- Action: MODIFY
- Location: Section 9 (Key Differentiators)
- Change: Ganti daftar 5 poin jadi 3 poin yang semuanya melayani 1 jiwa:
  ```
  1. Honest capacity — AI yang secara aktif meragukan komitmen tidak
     realistis, bukan yang selalu bilang "kamu pasti bisa"
  2. FORGOT vs SKIPPED — AI membedakan lupa vs sengaja skip sebagai bahan
     kejujuran, bukan asumsi "gagal"
  3. Invisible complexity — UI tetap sesederhana kertas, kejujuran itu ada
     di balik layar, bukan diumbar sebagai dashboard/grafik
  ```
  Hapus "Chat Room as evaluation data" sebagai poin diferensiator berdiri sendiri (posisikan sebagai mekanisme pendukung poin 1, bukan diferensiator terpisah) dan hapus "Adaptive AI personality" (diganti versi yang lebih sempit di TASK-D03)

**TASK-D02**
- File: `PRD.md`
- Action: MODIFY
- Location: Section 3.3 (Chat Room Tab)
- Change: Ganti framing dari "Brain-dump + Curhat + AI companion" jadi "Capacity check-in + capture task secukupnya untuk mendukung itu". Hapus contoh use-case "curhat biasa → AI respons dengan empati" sebagai kasus penggunaan utama — curhat tetap boleh diterima tapi diarahkan balik ke pertanyaan kapasitas ("kedengarannya berat, mau kita lihat beban minggu ini?"), bukan jadi ruang obrolan bebas tanpa arah

**TASK-D03**
- File: `PRD.md` & `DATABASE.md`
- Action: MODIFY
- Location: `PRD.md` Section 5 (Companion Agent Detail); `DATABASE.md` Section 6 (`conversation_logs`, kolom `tone_used`)
- Change: Pangkas tone dari 4 (`WARM`/`HONEST`/`MINIMAL`/`ENCOURAGING`) jadi 2:
  ```
  - HONEST (default): nada lugas, menyajikan data/konsekuensi apa adanya
  - GENTLE (kondisional): dipakai HANYA saat mendeteksi tanda burnout/
    overload nyata (bukan sekadar "mood negatif" umum) — tetap jujur,
    cuma lebih pelan cara menyampaikannya
  ```
  Update CHECK constraint atau dokumentasi `tone_used` di `DATABASE.md` mengikuti 2 nilai ini. `mood_detected` dipersempit tujuannya jadi khusus deteksi sinyal overload/burnout, bukan mood umum (senang/sedih/dst)

**TASK-D04**
- File: `technical.md`
- Action: MODIFY
- Location: Section 6 (Companion Agent Architecture), poin 3 "Adaptive Personality System"
- Change: Update "Tone Selection" dari 4 opsi ke 2 opsi (HONEST/GENTLE) sesuai TASK-D03. Update "Faktor Pengaruh" — hapus "waktu aktif (siang/malam)" sebagai faktor pemilihan tone (tidak relevan untuk misi kejujuran, itu peninggalan bahasa Opsi 3), pertahankan "completion_rate 7 hari" dan "consecutive misses" sebagai faktor utama karena keduanya relevan untuk mendeteksi butuh HONEST vs GENTLE

---

## Masalah 3: Palet & Tipografi DESIGN.md Menyimpang dari Kanon

**Masalah**: Draf `DESIGN.md` terbaru pakai `#FFFFFF`/`#000000` murni + signature "Mixed-Weight Headers", meninggalkan `Warm Off-White #FAF9F7`/`Ink Black #111111` dan pola Day Header/Day Strip/Task Row yang sudah divalidasi berkali-kali sebelumnya.

**Solusi**: Kembalikan token warna & komponen accordion ke versi kanon. "Mixed-Weight Headers" DIHAPUS (bukan cuma warnanya diganti) karena itu identitas tipografi yang menempel ke sistem desain yang sedang ditolak — mempertahankan sebagiannya cuma bikin 2 bahasa desain bercampur lagi.

**TASK-DS01**
- File: `DESIGN.md`
- Action: MODIFY
- Location: Section 2 (Color Palette & Roles)
- Change: Ganti seluruh token warna:
  ```
  Primary Foundation:
  - Warm Off-White (#FAF9F7) — background utama
  - Paper Gray (#F0EFED) — surface sekunder, day-strip collapsed

  Anchor & Interactive:
  - Ink Black (#111111) — SATU-SATUNYA aksen kuat, dipakai untuk active
    state & primary action saja, tidak dekoratif

  Typography & Text:
  - Charcoal (#1A1A1A) — teks utama
  - Warm Gray (#7A7772) — teks sekunder/meta
  - Hairline Gray (#DEDBD6) — border/divider
  ```
  Hapus seluruh referensi `#FFFFFF`/`#000000`/`#9CA3AF`/`#F9FAFB`/`#E5E7EB` dari draf sebelumnya

**TASK-DS02**
- File: `DESIGN.md`
- Action: REMOVE
- Location: Section 3 (Typography Rules), signature "Mixed-Weight Headers"
- Change: Hapus konsep ini sepenuhnya (termasuk contoh "Priority **Task**"). Kembalikan H1 day header ke: Extra-bold (800), uppercase, tight letter-spacing (-0.02em), sesuai spesifikasi kanon sebelumnya

**TASK-DS03**
- File: `DESIGN.md`
- Action: ADD
- Location: Section 4 (Component Stylings)
- Change: Kembalikan subsection yang hilang dari draf terbaru: "Day Header (Active/Expanded)", "Day Strip (Collapsed)", "Task Row", "Follow-up/Reschedule Chip" — salin spesifikasi dari versi kanon sebelumnya (day header TIDAK solid hitam, day strip pakai Paper Gray, checkbox outline circle yang terisi Ink Black saat done)

**TASK-DS04**
- File: `DESIGN.md`
- Action: KEEP
- Location: Section 6 (Design Constraints CONST-01 s/d CONST-04 di draf terbaru)
- Change: Prinsip "no shadow", "moderate border radius kecuali FAB", "monochrome" dipertahankan konsepnya — cuma nilai hex-nya yang diganti ikut TASK-DS01. Tidak perlu ditulis ulang dari nol

**TASK-DS05**
- File: `DESIGN.md`
- Action: ADD
- Location: Akhir dokumen
- Change: Tambah catatan singkat: "Sejak web app masuk scope (lihat Masalah 1), token warna di file ini juga jadi rujukan untuk `web/tailwind.config.ts` — pastikan nilai hex yang dipakai di Tailwind config disinkronkan ke sini, bukan sebaliknya"

---

## Belum Diselesaikan di Sesi Ini (Bukan Diabaikan)

Temuan audit sebelumnya yang TIDAK termasuk 3 keputusan hari ini — masih terbuka, jangan dianggap sudah beres:

- `auth.md`: Email+Password kembali muncul, bertentangan dengan alasan awal "zero password management"
- Risiko timeout Vercel serverless untuk rantai LangGraph multi-agent
- Endpoint `/debug/run-cron/*` tanpa autentikasi terdokumentasi
- CORS `allow_origins=["*"]` + `allow_credentials=True`
- `conversation_logs` tanpa kebijakan retensi/hapus, padahal berisi data sensitif
- `.env` master di-pass utuh ke build Flutter, bukan file client-only terpisah

Bawa ini ke sesi resolusi berikutnya kalau sudah siap dibahas.
