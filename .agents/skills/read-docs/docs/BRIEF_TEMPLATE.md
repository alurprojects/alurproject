# ALUR — Project Brief Template (1 Halaman per Masalah)

> **Status:** Template aktif | **Tanggal:** 2026-10-03 | **Pemilik:** Product Designer
> **Sumber Kebenaran:** `PRD.md` · `DESIGN.md` · `MOSCOW_FEATURES.md` · `technical.md` · `DATABASE.md`
> **Cara pakai:** Copy section §2 untuk setiap masalah (P1/P2/P3). Satu file brief boleh memuat banyak masalah, tapi satu masalah = satu template terisi penuh. Hapus contoh P1 saat membuat brief baru.

---

## §0. Filosofi & Definisi Operasional (Jangan Dihapus)

**Rumus tim:**

> **Keresahan / Masalah → Hipotesis Nilai → Fitur → Outcome Terukur → Kemudahan sebagai efek samping.**

**Definisi "Nyaman" di ALUR (disepakati 2026-10-03):**

> Nyaman = **kemudahan user dalam mengakses aplikasi** — menemukan, memahami, dan bertindak dalam **< 3 tap**, dengan **UI/UX yang rapih, tenang, dan konsisten**.
> Bukan dimanjakan. Bukan "kamu pasti bisa". Kadang ALUR harus tidak nyaman dulu agar jujur soal kapasitas (`PRD §1`: *"secara aktif jujur tentang kapasitas kamu"*).

**3 Pilar Kemudahan (wajib dicek per fitur):**

1. **Mudah Diakses** — fitur penting ≤ 3 tap dari tab utama. Navigasi 4-tab instant (0ms), state preserved (`DESIGN §7B`).
2. **Mudah Dipahami** — tanpa tutorial. Satu layar = satu keputusan. Empty state selalu kasih langkah berikut.
3. **Mudah Bertindak** — aksi utama 1-tap + bisa diabaikan/di-undo. AI tidak pernah eksekusi sepihak (DCDC invariant).

**Payung:** *Backend boleh kompleks, frontend wajib sesederhana kertas.* (Invisible Complexity — `MOSCOW §1.2`, `PRD §9`)

**Kalimat penolak (tempel di tiap review):**

> *Fitur yang tidak bikin user lebih jujur soal kapasitas tidak layak ada, betapapun nyamannya.*

---

## §1. Aturan "Rapih" (Checklist Wajib per Fitur)

Diambil dari `DESIGN.md`. "Rapih" bukan selera — ini kontrak:

- [ ] **Lapang:** padding horizontal 24px, spacing kelipatan 4/8px (`DESIGN §3, §5`)
- [ ] **Monokrom hangat:** `#FAF9F7` bg / `#111111` aksen aksi / `#F0EFED` surface / `#7A7772` teks sekunder / `#DEDBD6` hairline. No pure white/black (`CONST-01`)
- [ ] **Tipografi:** header Inter Black 900 / Extra-Bold 800, uppercase, tight -1.5px. Body Inter Regular 400 14px. Tidak ada font narrow/rounded (`CONST-02`)
- [ ] **Radius moderat 4–12px**, kecuali FAB lingkaran penuh (`CONST-03`). **No shadows, no gradients** (`CONST-04`)
- [ ] **Komponen reuse:** Day Header, Task Row, Chip pill, Primary Button, Chat bubble (`DESIGN §4`) — jangan invent komponen baru per fitur
- [ ] **Quiet motion:** tab instant, login 350ms easeInOutCubic fade+scale 0.98→1.00, logout 250ms fade (`DESIGN §7`)
- [ ] **Bahasa sehari-hari Indonesia:** "Ini 3 yang muat hari ini", bukan "Prioritization matrix computed"
- [ ] **Aksi destruktif konfirmasi 2-langkah** (contoh: Hapus Riwayat Chat — `PRD §3.5`)
- [ ] **Tetap terbaca saat user capek/overload:** kontras cukup, tap target ≥ 44px, tidak ada wall-of-text

---

## §2. Template Brief (Copy per Masalah)

### 2.1 Identitas

| Field | Isi |
| :--- | :--- |
| **ID Masalah** | P__ — Judul singkat (cth: P1 — Bingung prioritas tiap pagi) |
| **Penulis / Tanggal** | Nama — YYYY-MM-DD |
| **Status** | Draft / Divalidasi / Siap grooming |
| **Fitur terkait (ID MoSCoW)** | M__ / S__ / C__ (`MOSCOW_FEATURES.md`) |

### 2.2 Keresahan + Behaviour (Inti Brief)

1. **Keresahan (1 kalimat, bahasa user):**

   > _Contoh: "Tiap pagi bingung mau ngerjain yang mana dulu."_

2. **Behaviour — kapan, di mana, ngapain (5W):**

   - Kapan terjadi (jam/hari/pemicu)? :
   - Di mana (layar/konteks)? :
   - Apa yang dilakukan 5 menit sebelum? :
   - Apa yang dilakukan 5 menit sesudah? :
   - Frekuensi (x/minggu) + durasi terbuang (menit)? :

3. **Bukti (wajib minimal 1):**

   - Kutipan user / observasi / screenshot / data baseline:
   - Workaround sekarang + apa yang gagal darinya:

4. **Siapa yang TIDAK mengalami ini (batas scope):**

   >

### 2.3 Target Market (Perilaku > Umur)

> Umur 18–35 hanya guardrail rekrutmen, bukan definisi segmen (`PRD §1`). Pilih 1 persona primer:

- [ ] **The Overplanner** — bikin >8 task/hari, tuntas <50%. Butuh M6 warning jujur.
- [ ] **The Brain-dumper** — ide berserakan di ≥3 app/chat-ke-diri-sendiri. Butuh M4 capture 1 baris.
- [ ] **The Guilty Skipper** — skip lalu merasa gagal, butuh FORGOT vs SKIPPED + nada GENTLE (M9, S1).
- [ ] Lainnya: ___ (definisikan perilaku kapasitasnya, bukan umurnya)

**Konteks pemakaian:** Pagi sebelum kerja / sela kerja / malam refleksi / ___

### 2.4 Hipotesis Nilai → Fitur → Kemudahan

1. **Hipotesis nilai (1 kalimat, bisa salah):**

   > _Kami percaya [persona] yang [behaviour] akan [outcome] jika [fitur], karena [alasan]._

2. **Solusi inti (maks 2 kalimat, bukan daftar UI):**

   >

3. **Cek 3 Pilar Kemudahan:**

   - Diakses: berapa tap dari tab utama? (target ≤ 3) :
   - Dipahami: apa yang dibaca user dalam 5 detik? :
   - Bertindak: apa aksi 1-tap-nya? Bisa diabaikan? :

4. **Sketsa UI (referensi DESIGN, bukan mock baru):**

   - Komponen reuse: Task Row / Chip / Card / Chat bubble / ___ :
   - Empty state berbunyi: "___" + tombol "[___]":

### 2.5 Filter ALUR (Wajib Lolos Semua)

- [ ] **Honest Capacity** — apakah ini bikin user jujur soal kapasitas, bukan "kamu pasti bisa"? (`MOSCOW §1.2`)
- [ ] **Invisible Complexity** — apakah kompleksitas tetap di backend, frontend tetap kertas?
- [ ] **FORGOT vs SKIPPED** — jika menyentuh task gagal, apakah membedakan lupa vs sengaja skip?
- [ ] **DCDC** — apakah AI hanya usul, eksekusi tetap user? Tidak ada auto-pindah sepihak.

Jika salah satu gagal → tolak atau revisi. Tulis alasan di sini jika dikecualikan:

### 2.6 Non-Goals Eksplisit (Wajib Isi Minimal 1)

> Lihat `PRD §8` + `MOSCOW §5` (W1–W9). Contoh: no streak/gamifikasi (W3), no dashboard grafik (W2), no auto tanpa approval (W1), no Chat di Web v1 (W6).

1. ___
2. ___

### 2.7 Metrik & Asumsi Risiko

**Outcome (pilih 1 primer, bukan "nyaman"):**

| Kandidat | Target awal | Sumber data |
| :--- | :--- | :--- |
| % user kerjakan ≥1 dari Top 3 (P1) | ≥ 60% hari aktif | `morning_briefs.opened_at` + `tasks.status` |
| Completion rate harian (P2) | naik ≥ 20% vs baseline | `tasks` |
| Acceptance rate reschedule (P2) | ≥ 50% | `task_suggestions.status` |
| % baca insight mingguan (P3) | ≥ 40% | `ai_insights.surfaced` |
| DCDC (North Star) | tren naik mingguan | follow-up chip + capacity taps |

Primer untuk brief ini: ___ dengan target ___

**Asumsi paling berisiko (1 saja, yang jika salah fitur mati):**

> _Contoh: "User mau input estimasi durasi." Rencana validasi: ___

**Keputusan rilis:** R1 Fondasi / R2 Prioritas Pagi / R3 Reschedule+Insight / R4 Polish (`MOSCOW §8`)

---

## §3. Contoh Terisi — P1 (Hapus Saat Pakai Template Baru)

| Field | Isi |
| :--- | :--- |
| ID | P1 — Bingung prioritas tiap pagi |
| Fitur | M5 Morning Brief Top 3, M6 Capacity Check, M4 Brain-dump |

**Keresahan:** "Buka app jam 08:00, lihat 12 task tanpa urutan, scrolling 15 menit, akhirnya kerjakan yang paling gampang."

**Behaviour:** Terjadi tiap hari kerja 07:30–09:00 di To-do tab. Sebelum: buka HP di kasur/kereta. Sesudah: kerjakan task ringan, task berat jadi MISSED. Frekuensi 5x/minggu. Workaround: catat ulang di kertas / chat-ke-diri-sendiri di WA — gagal karena tidak ada urutan + tidak ada cek muat.

**Persona:** The Overplanner, konteks pagi sebelum kerja.

**Hipotesis:** Kami percaya Overplanner yang scrolling 15 menit akan mengerjakan ≥1 prioritas jika diberi maks 3 task + 1 kalimat alasan + total ≤ kapasitas, karena keputusan dikecilkan dari 12 → 3.

**Kemudahan:** Diakses 0 tap (kartu di puncak Daily Focus saat buka app). Dipahami 5 detik ("Ini 3 yang muat hari ini 4.5/6 jam"). Bertindak: [Kerjakan] / abaikan tanpa konsekuensi. Dihitung via cron, bukan on-demand (hindari limit 10s Vercel — `MOSCOW §10.4`).

**Filter:** Lolos Honest Capacity (total Top 3 ≤ `daily_capacity_hours`), Invisible Complexity (narasi singkat, bukan dashboard — tolak W2), DCDC (bisa diabaikan).

**Non-Goals:** Tidak ada skor produktivitas/gamifikasi (W3). Tidak auto-jadwalkan tanpa tap (W1).

**Metrik primer:** % kerjakan ≥1 dari Top 3 ≥ 60%. **Asumsi risiko:** user percaya "3 cukup" — validasi 5 interview + prototype Figma kartu M5.

---

## §4. Paket Riset Lean (1–2 Minggu, Stop Rule Jelas)

Jangan riset "butuh to-do list?". Validasi sempit:

- [ ] **5–6 interview "kemarin pagi" (30 mnt):** jam berapa buka to-do, berapa task, yang dipilih pertama apa, yang gagal apa + kenapa. Ambil bahasa asli untuk copy.
- [ ] **Diary 3 hari:** screenshot to-do pagi vs malam. Hitung baseline completion rate.
- [ ] **1 prototype test (Figma):** kartu M5 Top 3 + chip M9 FORGOT/SKIPPED. Tanya: 3 cukup? Wording menghakimi atau membantu? Kapan `(?)` clarify (C3) boleh muncul?
- [ ] **Stop rule:** berhenti jika 3 pola berulang muncul + asumsi risiko terjawab. Lanjut grooming.

Checklist grooming ke `MOSCOW §11`: copy M5, chip M9, default `daily_capacity_hours`, timing C3, urutan C4 vs C5.

---

## Changelog

| Tanggal | Perubahan |
| :--- | :--- |
| 2026-10-03 | v1 — Template dibuat dari hasil diskusi brief + definisi "nyaman = kemudahan akses (UI/UX rapih)". Referensi PRD/DESIGN/MOSCOW. Contoh P1 terisi. |
