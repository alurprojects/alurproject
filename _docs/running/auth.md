# Spesifikasi & Implementasi Auth (Login & Sign Up)

Dokumen ini mendefinisikan alur, antarmuka, dan spesifikasi otentikasi pada proyek ALUR sesuai dengan `_docs/running/DESIGN.md` dan `_docs/running/PRD.md`.

---

## 1. Metode Otentikasi
Otentikasi ALUR **hanya mendukung satu metode** yang di-handle oleh **Supabase Auth**:
1. **Google OAuth**: Single Sign-On (SSO) satu tap menggunakan akun Google via `supabase.auth.signInWithOAuth(provider: OAuthProvider.google)`.

*Catatan: Pendaftaran via Email & Password tidak diaktifkan untuk meminimalisir hambatan (friction) saat pendaftaran awal dan menyederhanakan arsitektur MVP.*

---

## 2. Alur Sistem & Koneksi Database

### Alur Masuk / Daftar (Single Flow)
1. User menekan tombol "Continue with Google" di aplikasi Flutter.
2. Flutter memanggil SDK Supabase: `supabase.auth.signInWithOAuth(provider: OAuthProvider.google)`
3. Supabase Auth membuat atau memverifikasi data kredensial di skema internal `auth.users`.
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
