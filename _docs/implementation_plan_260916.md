# Implementation Plan: ALUR Rebuild (3-Tab, Auth, & New Design System)

Berdasarkan pembaruan `PRD.md`, `DESIGN.md`, `DATABASE.md`, dan `technical.md`, berikut adalah rencana implementasi bertahap untuk membangun struktur aplikasi yang sesuai dengan arsitektur baru.

## User Review Required

> [!IMPORTANT]
> Mohon tinjau langkah-langkah di bawah ini. Fokus utama rencana ini adalah membangun **fondasi (Autentikasi & Desain B&W)** terlebih dahulu, menyatukan UI *To-do list* yang sudah ada ke dalam kerangka **3-Tab**, lalu membangun kerangka UI untuk **Calendar** dan **Profile**.

## Proposed Changes

### Tahap 1: Design System & Font (Sesuai Desain Baru)
Menyesuaikan tema Flutter agar mengadopsi standar visual *high-contrast black-and-white* yang membulat (rounded) dan *playful*.

#### [MODIFY] `mobile/pubspec.yaml`
- [x] Tambahkan package `google_fonts` untuk menggunakan font **Nunito** atau **Fredoka** sebagai font utama aplikasi.

#### [MODIFY] `mobile/lib/core/theme/app_theme.dart` (atau `app_colors.dart`)
- [x] Hapus warna *Warm Off-White/Ink Black*, ubah palet menjadi `Pure Black (#000000)` dan `Pure White (#FFFFFF)`.

#### [MODIFY] `mobile/lib/widgets/` (Global Components)
- [x] Buat/perbarui komponen *Button* menjadi kapsul bulat penuh (*fully rounded pill*).
- [x] Sesuaikan komponen penanda (*checkbox/day selector*) mengikuti gaya *solid black fill* ketika aktif.

---

### Tahap 2: Autentikasi (Supabase Auth)
Menyiapkan halaman login (Onboarding) dan me-routing user berdasarkan *state* autentikasi.

#### [NEW] `mobile/lib/services/supabase_service.dart`
- [ ] Inisialisasi klien Supabase di Flutter menggunakan *environment variables*.

#### [NEW] `mobile/lib/screens/auth/login_screen.dart`
- [ ] Buat halaman login bergaya bersih dengan ilustrasi *line-art* dalam bingkai asimetris (*blob*).
- [ ] Sertakan tombol aksi utama (misal: "Sign in with Google" atau otentikasi dasar/email).

#### [NEW] `mobile/lib/screens/auth/auth_gate.dart`
- [ ] Widget *router* untuk mengecek *auth state*. Jika user memiliki sesi aktif $\rightarrow$ arahkan ke `MainScreen`. Jika tidak $\rightarrow$ arahkan ke `LoginScreen`.

---

### Tahap 3: Kerangka Navigasi (3-Tab Layout)
Menghubungkan *To-do list* yang sudah ada ke struktur navigasi baru.

#### [NEW] `mobile/lib/screens/main_screen.dart`
- [ ] Buat *Scaffold* utama yang menampung komponen `BottomNavigationBar`.
- [ ] Bar navigasi datar (*flat white*) dengan 3 menu: `Checklist` (To-do), `Calendar`, dan `User` (Profile).
- [ ] Tab 1 mengarah ke *widget* `WeeklyScreen` yang saat ini sudah berjalan.
- [ ] Tab 2 dan 3 mengarah ke halaman *placeholder* sementara.

---

### Tahap 4: Calendar Tab (Tahap A)
Membuat fondasi UI untuk *Calendar Tab* (Visualisasi *Time-block* harian tanpa integrasi GCal eksternal).

#### [NEW] `mobile/lib/screens/calendar/calendar_screen.dart`
- [ ] Halaman *Calendar* dengan navigasi tanggal sederhana di bagian atas.

#### [NEW] `mobile/lib/widgets/calendar/timeline_grid.dart` & `unscheduled_strip.dart`
- [ ] Render garis jam dari 06:00 hingga 22:00.
- [ ] Siapkan ruang *Unscheduled* di atas tabel jam untuk menampung *task* tanpa waktu spesifik.
- [ ] Buat *mock data* untuk memvisualisasikan bagaimana sebuah blok waktu (*Time-block*) akan di-render.

---

### Tahap 5: Profile Tab & Goals
Membangun halaman pengaturan *user* dan fitur penargetan (*Goals*).

#### [NEW] `mobile/lib/screens/profile/profile_screen.dart`
- [ ] Halaman yang menampilkan informasi akun pengguna saat ini dan tombol Logout.

#### [NEW] `mobile/lib/widgets/profile/goal_list_item.dart`
- [ ] Tampilan daftar *Goals*. Merujuk pada aturan desain, ini menggunakan pola visual *task row* sederhana (tidak berbentuk kartu terpisah) dengan label status yang teksnya inline.

---

## Verification Plan

### Automated Tests
- [ ] Menjalankan `flutter analyze` dan memastikan kode `0 issues`.
- [ ] Menjalankan `flutter test` untuk memvalidasi bahwa `WeeklyScreen` dan komponen lama yang dibungkus oleh navigasi baru tidak mengalami *breaking changes* (harus 7/7 *passed*).

### Manual Verification
- [ ] Menjalankan aplikasi secara langsung di *emulator* (Android/iOS).
- [ ] Menguji alur *login*: memastikan aplikasi memulai dari layar masuk dan berpindah ke layar utama (3-Tab) setelah autentikasi.
- [ ] Mengonfirmasi seluruh aplikasi menggunakan font *rounded* (Nunito/Fredoka) dan menggunakan warna hitam-putih murni.
- [ ] Menekan ikon di bilah navigasi bawah untuk memastikan transisi antar *To-do List*, *Calendar*, dan *Profile* berjalan dengan mulus.
