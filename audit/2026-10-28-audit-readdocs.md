# Audit read-docs — 2026-10-28

**Scope:** `.agents/skills/read-docs/` (28 file, 249 KB).
**Metode:** inventaris `Get-ChildItem -Recurse`; grep repo-wide untuk setiap kandidat; cek isi kepala file; cek referensi di kode & README. Tidak ada file yang dihapus dalam audit ini — ini laporan vonis.

**Vonis:** 17 KEEP · 11 tidak perlu dipertahankan (7 hapus, 4 merge-lalu-hapus) → folder turun 28 → 17 file (−39% isi, −95 KB).
**Load yang diasumsikan:** dokumen dibaca ulang oleh agent di setiap sesi. Setiap file yang tak terpakai = biaya konteks berulang, bukan sekadar rapi-rapian.

---

## 1. Tabel vonis lengkap (28 file)

| # | File | KB | Vonis | Alasan |
| :-: | :--- | --: | :--- | :--- |
| 1 | `SKILL.md` | 6.3 | **KEEP + FIX** | Satu-satunya routing table. Perbaiki: baris `feedback.md` menunjuk file yang **tidak ada** (dead link), `DESIGN-WEB.md`/`mindmap.md`/`landing-page/`/`resolusi/` tidak punya baris routing. |
| 2 | `docs/PRD.md` | 9.1 | **KEEP** | SSOT visi, UX, data model. Dirujuk SKILL, AGENTS, plans. |
| 3 | `docs/DESIGN.md` | 8.6 | **KEEP (direvisi)** | SSOT design. Sudah ditulis ulang ke dark editorial (v2). |
| 4 | `docs/DESIGN-WEB.md` | 3.1 | **MERGE → §8 DESIGN.md, lalu hapus** | Isinya tinggal 1 aturan yang masih benar (kartu `w-full` per task). Sisanya hantu: `DayColumn.tsx`, `WeekGrid.tsx`, `SomedayDrawer.tsx` **tidak ada** di `web/app/components/planner/`; link memakai path mesin lain (`e:/Work-Learn/...`). |
| 5 | `docs/technical.md` | 18.7 | **KEEP** | SSOT stack, API contract, LangGraph. Dirujuk SKILL + plans. |
| 6 | `docs/DATABASE.md` | 27.4 | **KEEP** | SSOT schema, RLS, pg_cron. Dirujuk SKILL + plans. |
| 7 | `docs/auth.md` | 5.6 | **KEEP** | SSOT auth + sketsa UI login. |
| 8 | `docs/ENV_GUIDE.md` | 7.6 | **KEEP** | SSOT env var, isolasi client/server. |
| 9 | `docs/DEPLOYMENT_GUIDE.md` | 14.3 | **KEEP** | SSOT deploy (Vercel/VPS). |
| 10 | `docs/MOSCOW_FEATURES.md` | 20.9 | **KEEP** | SSOT MoSCoW; menyatakan sendiri bahwa `from_llm/` dan `plans/` bukan sumber prioritas. |
| 11 | `docs/mindmap.md` | 11.7 | **DELETE** (opsional: pindahkan 3 blok mermaid ke `diagrams/`) | Ringkasan visual yang **menduplikasi** PRD + technical + DATABASE + plans. Versi terakhir 2026-09-30 v2 → tidak memuat web pivot/MoSCoW terkini. Satu-satunya perujuk: `README.md:67`. Teksnya juga rusak encoding (`�?"`). |
| 12 | `docs/from_llm/MOSCOW_FEATURES_CLAUDE.md` | 11.6 | **DELETE** | Draft MoSCoW lama yang **secara eksplisit sudah dinyatakan bukan sumber** oleh `MOSCOW_FEATURES.md:239`. Dua dokumen prioritas = drift. |
| 13 | `docs/resolusi/resolusi-audit-260916.md` | 10.5 | **DELETE** | Instruksi atomik audit 16 Sep. Semua keputusannya sudah masuk PRD/DESIGN/technical (CONST-08 dst). Log historis, bukan spec aktif. |
| 14 | `docs/resolusi/resolusi-B-260917.md` | 12.1 | **DELETE** | Tindak lanjut Section B `feedback.md` (file yang kini tidak ada). Tidak bisa dieksekusi tanpa konteks yang sudah hilang. |
| 15 | `docs/resolusi/resolusi-platform-cron-260917.md` | 7.5 | **DELETE** | Keputusan platform/cron 17 Sep; sudah tercermin di `DEPLOYMENT_GUIDE.md` §5 dan DATABASE §11. |
| 16 | `docs/landing-page/landing-page.md` | 7.2 | **KEEP** (jadi satu-satunya file landing) | Landing page belum diimplementasikan (tidak ada route di `web/app`), jadi ini spec masa depan. Layak disimpan sebagai satu file. |
| 17 | `docs/landing-page/copywriting.md` | 5.0 | **MERGE → landing-page.md** | Spec copy terpisah untuk halaman yang belum ada. Dua file untuk satu deliverable = beban baca ganda. |
| 18 | `docs/landing-page/design-system.md` | 4.5 | **MERGE → landing-page.md** | Design system landing memakai token yang sama dengan `DESIGN.md`; menyimpannya terpisah mengundang drift palet. |
| 19 | `docs/landing-page/components.md` | 6.8 | **MERGE → landing-page.md** | Daftar komponen untuk halaman yang belum dibangun. Cukup sebagai satu bagian di file konsep. |
| 20 | `docs/plans/2026-09-26_core-implementation.md` | 6.7 | **KEEP** | Checklist implementasi inti, aturan proyek: satu file per fitur. Catatan: merujuk `_docs/running/` yang **tidak ada** (path mati, bukan alasan hapus). |
| 21 | `docs/plans/2026-09-28_morning-brief-rag.md` | 29.3 | **KEEP** | Plan fitur terbesar; pasangan dari file exec di bawah. File terbesar di folder — pertimbangkan kompresi, bukan hapus. |
| 22 | `docs/plans/2026-09-30_moscow-ai-task-manager.md` | 13.3 | **KEEP** | Plan fitur MoSCoW; masih relevan ke roadmap R2–R4. |
| 23 | `docs/plans/2026-10-03_web-first-target-harian.md` | 4.4 | **KEEP** | Plan terbaru (web-first + Target Harian), masih jadi arah aktif. |
| 24 | `docs/exec/2026-09-28_exec-morning-brief-rag.md` | 5.9 | **KEEP** | Satu-satunya checklist eksekusi; format yang diwajibkan AGENTS.md. |
| 25 | `docs/track-progress/2026-09-30.md` | 2.5 | **KEEP** | Log harian. Append-only — tidak boleh dihapus (AGENTS.md). Juga jadi template. |
| 26 | `docs/track-progress/2026-10-03.md` | 3.1 | **KEEP** | Log harian, append-only. |
| 27 | `docs/track-progress/2026-10-28.md` | 2.1 | **KEEP** | Log harian aktif, append-only. |
| 28a | `claude/ALUR_rekap_penyesuaian_dokumen.md` | 27.4 | **DELETE** | **Di luar `docs/`** → melanggar SSOT. Isinya 30+ usulan revisi dokumen berstatus "usulan", bukan spec. Rekomendasinya sudah diterapkan / sudah basi. 27 KB terbaca agent tanpa pernah jadi acuan. |
| 28b | `claude/ALUR_rekap_solusi_dan_user_targeting.md` | 11.3 | **DELETE** | Sama: di luar `docs/`, isinya hipotesis pasar ("semua angka adalah hipotesis") yang tidak boleh dipakai sebagai fakta produk. |

> Baris 28a/28b = total 28 file (dua file dihitung satu nomor karena sekelompok).

---

## 2. Temuan struktural (bukan file)

1. **Dead link di routing:** `SKILL.md:33` → `docs/feedback.md` **tidak ada**. Selama ini agent yang mencari "status audit" diarahkan ke file kosong. Ganti baris itu ke `track-progress/` + changelog `plans/`.
2. **Folder tak terdaftar:** `claude/`, `docs/from_llm/`, `docs/resolusi/`, `docs/landing-page/`, `docs/mindmap.md` — semuanya tidak ada di routing table, jadi agent menemukannya lewat `glob` dan membaca semuanya. Inilah penyebab "overload" sebenarnya: bukan jumlah dokumen inti (9 file, 127 KB), tapi 11 file bayangan.
3. **Duplikasi otoritas:** `MOSCOW_FEATURES.md` vs `from_llm/MOSCOW_FEATURES_CLAUDE.md` — dua daftar prioritas. Satu harus mati.
4. **Spec hantu:** `DESIGN-WEB.md` merujuk 3 komponen yang sudah tidak ada.
5. **`mindmap.md` basi:** versi 2026-09-30, sebelum web pivot & R2b, tapi masih ditaut README.
6. **Encoding rusak** di `mindmap.md`, `landing-page/*`, `resolusi/*` (`�?"`, `A�`, `dY"`). File yang dibaca agent menghasilkan mojibake di konteks.

---

## 3. Urutan eksekusi (kalau disetujui)

1. Hapus 2 file `claude/` — nol referensi, nol risiko.
2. Hapus 3 file `docs/resolusi/` + `from_llm/MOSCOW_FEATURES_CLAUDE.md` — duplikat/keputusan yang sudah diterapkan.
3. Gabungkan 3 file `landing-page/` ke `landing-page.md`, hapus yang asli.
4. Pindahkan 3 blok mermaid `mindmap.md` ke `diagrams/` (kalau mau), lalu hapus `mindmap.md` + ganti link `README.md:67`.
5. Hapus `DESIGN-WEB.md` (§8 DESIGN.md sudah menampung aturan yang masih berlaku).
6. Perbaiki `SKILL.md`: buang baris `feedback.md`, tambah baris `landing-page` (setelah merge) dan `plans/`/`exec/`.

**Yang TIDAK boleh dihapus:** 9 dokumen inti, 4 plans, 1 exec, 3 track-progress. Itu semua punya perujuk atau diwajibkan aturan proyek.

---

## 4. Hasil

| Metrik | Sebelum | Sesudah | Δ |
| :--- | --: | --: | :--- |
| File | 28 | 17 | −11 (−39%) |
| KB | 249 | ~154 | −95 KB (−38%) |
| File tanpa perujuk jelas | 11 | 0 | — |

Verdict: dokumen inti sehat. Yang menumpuk adalah **rekap, draft, dan log historis** — semuanya bisa hilang tanpa kehilangan satu keputusan pun. Belum dieksekusi (menunggu persetujuan).
