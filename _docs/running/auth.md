# Spesifikasi & Implementasi Auth (Login & Sign Up)

Dokumen ini mendefinisikan alur, antarmuka, dan spesifikasi otentikasi pada proyek ALUR sesuai dengan `_docs/running/DESIGN.md` dan `_docs/running/PRD.md`.

---

## 1. Metode Otentikasi
Otentikasi ALUR **hanya mendukung satu metode** yang di-handle oleh **Supabase Auth**:
1. **Google OAuth (Native & Web)**: Single Sign-On (SSO) satu tap menggunakan akun Google via `GoogleSignIn` (di Android/iOS) dilanjutkan dengan `supabase.auth.signInWithIdToken()`. Untuk platform Web tetap menggunakan `supabase.auth.signInWithOAuth()`.

*Catatan: Pendaftaran via Email & Password tidak diaktifkan untuk meminimalisir hambatan (friction) saat pendaftaran awal dan menyederhanakan arsitektur MVP.*

---

## 2. Alur Sistem & Koneksi Database

### Alur Masuk / Daftar (Single Flow)
1. User menekan tombol "Continue with Google" di aplikasi Flutter.
2. Flutter memanggil Native Google Sign-in dialog (`GoogleSignIn().signIn()`).
3. Google merespons dengan `idToken` dan `accessToken`.
4. Flutter mengirimkan token tersebut ke Supabase: `supabase.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: ..., accessToken: ...)`
5. Supabase Auth membuat atau memverifikasi data kredensial di skema internal `auth.users`.
4. **Trigger Database:** Secara otomatis, trigger `on_auth_user_created` (didefinisikan di `DATABASE.md`) berjalan di PostgreSQL dan membuat baris profil di `public.users` jika belum ada.
5. Flutter menerima **JWT Session** dan menyimpannya secara lokal (via `shared_preferences` / Supabase Auth persistence default).
6. Setiap request API ke Backend (FastAPI) akan menyertakan header: `Authorization: Bearer <token>`.

### Auto-Login & Session Persistence
- Saat aplikasi dibuka, Flutter memeriksa apakah session masih aktif (`supabase.auth.currentSession != null`).
- Jika aktif → langsung arahkan ke `MainScreen`.
- Jika belum login / expired → tampilkan `AuthScreen`.

---

## 3. Desain UI & Sketsa Antarmuka

Mengikuti panduan `DESIGN.md`:
- **Canvas / Background**: Warm Off-White (`#FAF9F7`)
- **Aksen Utama / Tombol**: Ink Black (`#111111`) dengan teks putih
- **Teks Utama**: Charcoal (`#1A1A1A`)
- **Teks Sekunder / Meta**: Warm Gray (`#7A7772`)
- **Header Illustration & Glow**: Ilustrasi line-art monokrom dengan sentuhan halus *pastel glow* di latar belakang.

### Sketsa Layar: Auth Screen (Single Screen)

```text
+---------------------------------------------------+
|                                                   |
|                                                   |
|       ( Ilustrasi Line-Art Duduk + HP )           |
|       [ Soft pastel radial glow background ]      |
|                                                   |
|                                                   |
|       Welcome to ALUR                             |
|       Your realistic daily planner.               |
|                                                   |
|                                                   |
|                                                   |
|  +---------------------------------------------+  |
|  |           (G) Continue with Google          |  |
|  +---------------------------------------------+  |
|                                                   |
|       By continuing, you agree to our Terms       |
+---------------------------------------------------+
```

---

## 4. Ketentuan Styling Komponen

1. **Tombol Google OAuth (Primary Action)**:
   - Background: Ink Black (`#111111`) atau White dengan border Hairline Gray (`#DEDBD6`) bergantung pada kontras yang diinginkan. Sesuai standar MVP: gunakan tombol putih dengan ikon Google standar dan teks Charcoal (`#1A1A1A`), border-radius 8px, padding vertical 14px.
2. **Ilustrasi & Glow**:
   - Line-art monokrom (stroke Charcoal) figur duduk membawa smartphone.
   - Subtle pastel glow di belakang (radial gradient dengan perpaduan warna lavender, soft cyan, dan peach dengan opacity sangat lembut ~0.15–0.25).
3. **Teks Pendukung**:
   - Judul: Charcoal (`#1A1A1A`), font weight 700, ukuran besar.
   - Deskripsi & Terms: Warm Gray (`#7A7772`), font weight 400.

---

## 5. Spesifikasi Animasi & Transisi (Login & Logout Motion UX)

Untuk menjaga pengalaman pengguna tetap tenang (*calm, tactile, and unobtrusive*) sesuai filosofi ALUR:

### A. Transisi Masuk (Login Transition: AuthScreen → MainScreen)
- **Mekanisme**: Diatur oleh `AnimatedSwitcher` pada `AuthGate` yang merespons perubahan stream `onAuthStateChange` (`SIGNED_IN` / session aktif).
- **Efek Visual**: Kombinasi *Cross-Fade* (Opacity 0.0 → 1.0) dengan *Subtle Elevation Lift* (Scale 0.98 → 1.00) untuk memberikan transisi mulus dan elegan saat masuk ke kanvas utama.
- **Durasi**: **350ms**.
- **Kurva (*Easing*)**: `Curves.easeInOutCubic` (akselerasi halus di awal, deselerasi tenang di akhir).
- **State Feedback**: Selama komunikasi dengan Google OAuth dan Supabase berlangsung, tombol `GoogleSignInButton` menampilkan *loading indicator* dan berstatus nonaktif guna mencegah *multiple taps*.

### B. Transisi Keluar (Logout Transition: MainScreen → AuthScreen)
- **Mekanisme**: Dipicu ketika pengguna menekan tombol "Log Out" (di Tab Profile) yang memanggil `authService.signOut()`.
- **Efek Visual**: *Pure Clean Fade* (Opacity 1.0 → 0.0 → 1.0) menuju `AuthScreen`.
- **Durasi**: **250ms**.
- **Kurva (*Easing*)**: `Curves.easeOutCubic`.
- **Pembersihan State**: Seluruh status aktif di `MainScreen` direset kembali ke Tab 0 (To-do), session token dibersihkan, dan layar kembali ke landing `AuthScreen` tanpa *screen flicker* atau *blank page*.

