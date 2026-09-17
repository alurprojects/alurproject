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

Flutter (sejak versi 3.7+) memiliki fitur bawaan untuk membaca file `.env` secara langsung saat kompilasi (*compile-time*) menggunakan flag `--dart-define-from-file`.

> [!CAUTION]
> **PENTING:** Mobile app HANYA boleh membaca `.env.client`, TIDAK PERNAH `.env` master. Ini mencegah `SUPABASE_SERVICE_ROLE_KEY` dan API key LLM ter-compile ke dalam APK/IPA meski tidak sengaja direferensikan di kode Dart — proteksinya di level file, bukan cuma disiplin coding.

#### 1. File `.env.client` (di root repo, sejajar `.env`)
Berisi HANYA variabel berprefix `PUBLIC_*`:
```env
PUBLIC_SUPABASE_URL=https://iajqnfcpljkwhvbicylh.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
```
File ini di-generate/disalin manual dari `.env`, bukan symlink.

#### 2. Membaca Variabel dalam Kode Dart (`mobile/lib/core/config/env.dart`):
```dart
class AppEnv {
  static const String supabaseUrl = String.fromEnvironment(
    'PUBLIC_SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'PUBLIC_SUPABASE_ANON_KEY',
    defaultValue: '',
  );
}
```

#### 3. Menjalankan / Build Flutter via CLI:
```bash
# Menjalankan di emulator / device
flutter run --dart-define-from-file=../.env.client

# Build APK release
flutter build apk --dart-define-from-file=../.env.client
```

#### 4. Konfigurasi VS Code Debugger (`.vscode/launch.json`):
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "ALUR Mobile (Debug)",
      "request": "launch",
      "type": "dart",
      "program": "mobile/lib/main.dart",
      "toolArgs": [
        "--dart-define-from-file",
        "${workspaceFolder}/.env.client"
      ]
    }
  ]
}
```

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
