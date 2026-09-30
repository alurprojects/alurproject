# Design System: ALUR Web (Minimalist Weekly Notebook View)

Dokumen ini memperluas `DESIGN.md` utama khusus untuk antarmuka Web ALUR, mengadopsi model notebook mingguan ultra-minimalis yang disempurnakan dari Tweek.so.

---

## 1. Perbaikan Desain & Layout (Sesuai Referensi Tweek)

### A. Full-Width Card System
- **Masalah Sebelumnya**: Background warna stabilo hanya membungkus teks inline (`inline span`) sehingga saat teks melipat ke bawah menjadi kotak sempit yang terhimpit.
- **Penyempurnaan**: Seluruh tugas (baik yang polos maupun berwarna stabilo) sekarang menjadi **kartu penuh (`w-full`)** yang membentang rapi memenuhi lebar kolom hari. Sudut kartu dibulatkan secara elegan (`rounded-xl` dengan border halus yang senada), dengan checkbox di sisi kiri dan konten teks membentang lebar.

### B. Task Edit Popup Modal (Persis Mockup Tweek)
Ketika pengguna mengklik kartu tugas manapun, akan muncul **Popup Modal Edit** gelap/kontras tinggi dengan struktur:
1. **Top Bar**:
   - Tanggal tugas (`📅 Tue, 29 Sep 2026`).
   - Aksi cepat: Hapus tugas (`Trash2`), Ulangi (`RotateCw`), Titik pemilih warna stabilo (*Color Dot Indicator*), Pengingat (`Bell`), opsi lainnya (`...`), dan tombol tutup (`X`).
2. **Title Row**:
   - Input judul besar berbobot tebal (`text-2xl font-bold`).
   - Tombol centang bulat besar di kanan (`CheckCircle2`) untuk menandai tugas selesai/belum selesai.
3. **Divider & Rich Text Toolbar**:
   - Garis pemisah tipis.
   - Ikon pemformatan: Heading (`H`), Bold (`B`), Italic (`I`), Bullet List (`:=`), Alignment (`≡`), dan Link (`🔗`).
4. **Extra Notes Area**:
   - Textarea catatan tambahan ("Add some extra notes here...").
5. **Subtasks Section**:
   - Daftar subtugas interaktif dengan checkbox penyelesaian.
   - Input inline `Add subtask... (press Enter)` dan ikon lampiran (`Paperclip`).

---

## 2. Struktur Komponen

- **[`page.tsx`](file:///e:/Work-Learn/Coding/Project/alur-project/Project/alur-project/web/app/page.tsx)**: State global, modal controller, & persistensi `localStorage`.
- **[`TaskItem.tsx`](file:///e:/Work-Learn/Coding/Project/alur-project/Project/alur-project/web/app/components/planner/TaskItem.tsx)**: Kartu tugas `w-full` dengan checkbox dan trigger klik untuk membuka modal popup.
- **[`TaskEditModal.tsx`](file:///e:/Work-Learn/Coding/Project/alur-project/Project/alur-project/web/app/components/planner/TaskEditModal.tsx)**: Popup modal edit lengkap sesuai gambar referensi Tweek.
- **[`DayColumn.tsx`](file:///e:/Work-Learn/Coding/Project/alur-project/Project/alur-project/web/app/components/planner/DayColumn.tsx)**: Kolom hari dengan garis bergaris dan input inline cepat.
- **[`WeekGrid.tsx`](file:///e:/Work-Learn/Coding/Project/alur-project/Project/alur-project/web/app/components/planner/WeekGrid.tsx)**: Penampung 7 hari seminggu.
- **[`SomedayDrawer.tsx`](file:///e:/Work-Learn/Coding/Project/alur-project/Project/alur-project/web/app/components/planner/SomedayDrawer.tsx)**: Laci backlog tugas belum terjadwal.
- **[`BrainDumpModal.tsx`](file:///e:/Work-Learn/Coding/Project/alur-project/Project/alur-project/web/app/components/planner/BrainDumpModal.tsx)**: Modal cepat untuk multi-tugas.
