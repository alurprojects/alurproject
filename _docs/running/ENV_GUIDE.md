# Panduan Konfigurasi Centralized Environment (`.env`)

Dokumen ini menjelaskan arsitektur, cara kerja, dan implementasi dari **file `.env` terpusat (*Single Source of Truth*)** pada proyek ALUR yang diakses bersama oleh seluruh platform: **Backend (FastAPI)**, **Web (Next.js)**, dan **Mobile (Flutter)**.

---

## 1. Arsitektur & Filosofi

Alih-alih membuat file `.env` terpisah di setiap folder platform (`backend/.env`, `web/.env`, `mobile/.env`) yang rentan mengalami *drift* (inkonsistensi data) dan memusingkan saat rotasi *credential*, ALUR menggunakan **satu file `.env` di root repository**:

```
alur/
├── .env                       ← [SINGLE SOURCE OF TRUTH] Variabel rahasia lokal (di-ignore git)
├── .env.example               ← Template variabel (aman di-commit ke git)
├── .gitignore                 ← Memastikan .env tidak pernah ter-commit
├── _docs/
│   └── ENV_GUIDE.md           ← Dokumen panduan ini
├── backend/                   ← FastAPI (membaca ../.env)
├── web/                       ← Next.js (membaca ../.env via next.config / symlink)
└── mobile/                    ← Flutter (membaca ../.env via --dart-define-from-file)
```

---

## 2. Standar Konvensi Penamaan Variabel

Untuk mencegah bocornya *credential* rahasia server ke sisi client (browser/mobile), terapkan aturan prefix berikut:

| Kategori | Konvensi Prefix | Cakupan Akses | Contoh Variabel |
| :--- | :--- | :--- | :--- |
| **Publik / Client-Safe** | `PUBLIC_*` | Boleh dibaca oleh Mobile, Web, dan Backend | `PUBLIC_SUPABASE_URL`<br>`PUBLIC_SUPABASE_ANON_KEY` |
| **Rahasia Server-Only** | Tanpa `PUBLIC_` | **HANYA** boleh dibaca oleh Backend / Edge Function | `SUPABASE_SERVICE_ROLE_KEY`<br>`GEMINI_API_KEY`<br>`GROQ_API_KEY`<br>`DATABASE_URL` |

> [!CAUTION]
> **ATURAN KEAMANAN**:
> Variabel tanpa prefix `PUBLIC_` **TIDAK BOLEH** pernah diekspos ke kode Flutter atau Next.js client-side. Kunci seperti `SUPABASE_SERVICE_ROLE_KEY` memiliki hak akses bypass Row Level Security (RLS).

---

## 3. Cara Integrasi per Platform

### A. Backend (FastAPI / Python)

FastAPI menggunakan library `pydantic-settings` atau `python-dotenv` untuk membaca file `.env` di root direktori proyek.

#### Contoh Implementasi (`backend/app/core/config.py`):
```python
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

# Menemukan root direktori proyek (alur/)
ROOT_DIR = Path(__file__).resolve().parents[3] # sesuaikan dengan kedalaman folder app/core/
ENV_FILE = ROOT_DIR / ".env"

class Settings(BaseSettings):
    # Supabase
    PUBLIC_SUPABASE_URL: str
    PUBLIC_SUPABASE_ANON_KEY: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str
    DATABASE_URL: str = ""

    # AI Providers
    GEMINI_API_KEY: str = ""
    GROQ_API_KEY: str = ""

    # Server
    BACKEND_HOST: str = "0.0.0.0"
    BACKEND_PORT: int = 8000
    BACKEND_ENV: str = "development"

    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
```

---

### B. Web App (Next.js)

Secara default, Next.js mencari file `.env` di direktori kerjanya (`web/`). Agar Next.js otomatis membaca `.env` terpusat dari root:

#### Cara 1: Menggunakan `dotenv` di `next.config.mjs` / `next.config.js` (Direkomendasikan)
Di dalam `web/next.config.mjs`:
```javascript
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Muat .env dari root repository
dotenv.config({ path: path.resolve(__dirname, '../.env') });

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Petakan variabel PUBLIC_* agar otomatis tersedia di sisi browser (NEXT_PUBLIC_*)
  env: {
    NEXT_PUBLIC_SUPABASE_URL: process.env.PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.PUBLIC_SUPABASE_ANON_KEY,
  },
};

export default nextConfig;
```

#### Cara 2: Symbolic Link (Alternatif)
Membuat symlink dari file root `.env` ke `web/.env.local`:
- **Windows (PowerShell Run as Administrator)**:
  ```powershell
  New-Item -ItemType SymbolicLink -Path "web/.env.local" -Target "../.env"
  ```
- **macOS / Linux**:
  ```bash
  ln -s ../../.env web/.env.local
  ```

---

### C. Mobile App (Flutter)

Flutter di proyek ALUR menggunakan package `flutter_dotenv` untuk membaca variabel pada saat *runtime*.

> [!CAUTION]
> **PENTING:** Karena file `.env` digabungkan sebagai aset aplikasi (terbaca di APK/IPA), file `.env` di folder `mobile` **HANYA** boleh berisi variabel berprefix `PUBLIC_*`. File `.env` master dari root tidak boleh disalin mentah-mentah ke dalam aset Flutter!

#### 1. Setup file `.env` di folder `mobile`
Salin file `.env.client` dari root repo ke dalam direktori `mobile` dengan nama `.env`. File ini **hanya** berisi:
```env
PUBLIC_SUPABASE_URL=https://iajqnfcpljkwhvbicylh.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
```

#### 2. Membaca Variabel dalam Kode Dart (`mobile/lib/core/config/env.dart`):
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppEnv {
  static String get supabaseUrl => dotenv.env['PUBLIC_SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['PUBLIC_SUPABASE_ANON_KEY'] ?? '';
}
```

Pastikan `dotenv.load(fileName: ".env");` sudah dipanggil di `main()` pada `main.dart`.

#### 3. Menjalankan / Build Flutter via CLI:
Karena sudah menggunakan `flutter_dotenv`, Anda tidak perlu lagi menyertakan flag panjang. Cukup jalankan:
```bash
# Menjalankan di emulator / device
flutter run

# Build APK release
flutter build apk
```

#### 4. Google Sign-In (Native)
Untuk menggunakan Native Google Sign-in:
1. Masuk ke **Google Cloud Console**.
2. Buat **OAuth 2.0 Client IDs** untuk platform **Android** (masukkan SHA-1 certificate dari keystore) dan **iOS** (masukkan Bundle ID).
3. Jika menggunakan platform iOS, Client ID perlu ditambahkan di `Info.plist`. Untuk Android, plugin secara otomatis mengaturnya berdasarkan konfigurasi SHA-1 di console.
4. Anda tidak perlu memasukkan Web Client ID ke dalam kode Flutter. Supabase Auth akan memverifikasi *idToken* Google asalkan Client ID Android/iOS terdaftar di *whitelist* (atau konfigurasi project Firebase/GCP yang sama).

---

## 4. Panduan Menambah Variabel Baru ke Depannya

Setiap kali ada *third-party service*, kredensial baru, atau konfigurasi baru:

1. **Buka `.env` di root repository**:
   Tambahkan variabel baru dengan nilai riil Anda.
2. **Perbarui `.env.example`**:
   Tambahkan variabel yang sama ke `.env.example` dengan nilai *dummy/placeholder* agar anggota tim lain mengetahui adanya variabel baru tersebut saat melakukan `git pull`.
3. **Tentukan Aksesnya**:
   - Jika dibutuhkan oleh Flutter/Next.js client-side, berikan awalan `PUBLIC_`.
   - Jika hanya untuk server backend, gunakan nama standar tanpa `PUBLIC_`.
4. **Perbarui kelas config/wrapper** di platform terkait (misalnya di `Settings` FastAPI, `next.config.mjs`, atau `AppEnv` Flutter).
5. **Jika variabel berprefix `PUBLIC_`**: Tambahkan juga ke `.env.client`. Tidak cukup hanya menambahkan di `.env` master — `.env.client` adalah file terpisah yang harus diperbarui secara manual.

---

## 5. Setup Awal untuk Developer Baru

Bagi developer yang baru pertama kali melakukan clone repository:
```bash
# 1. Salin template .env.example menjadi .env
cp .env.example .env

# 2. Buka file .env dan lengkapi kredensial yang masih kosong
# (misal: PUBLIC_SUPABASE_ANON_KEY, GEMINI_API_KEY, dll.)
```
