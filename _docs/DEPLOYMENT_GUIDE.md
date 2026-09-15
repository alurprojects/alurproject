# ALUR — Deployment & Infrastructure Guide

Dokumen ini adalah panduan teknis operasional (*step-by-step*) untuk mengonfigurasi, mendeploy, dan mengintegrasikan **Backend (FastAPI)** dan **Web Frontend (Next.js)** ke platform **Vercel** dengan domain kustom **`alurproject.web.id`**, beroperasi pada **100% Free-Tier (Zero Credit Card Required)**.

---

## 1. Topologi Domain & Arsitektur Sistem

```
                         Internet / DNS (alurproject.web.id)
                                      │
           ┌──────────────────────────┴──────────────────────────┐
           ▼                                                     ▼
┌────────────────────────────┐                        ┌────────────────────────────┐
│   https://alurproject.web.id│                        │ https://api.alurproject.web.id
│   (dan www.alurproject.web.id)                       │                            │
├────────────────────────────┤                        ├────────────────────────────┤
│ Vercel Project: alur-web   │                        │ Vercel Project: alur-backend│
│ Source: /web (Next.js)     │                        │ Source: /backend (FastAPI) │
│ Runtime: Node.js Edge/SSR  │                        │ Runtime: Python 3 Serverless│
└──────────────┬─────────────┘                        └──────────────┬─────────────┘
               │                                                     │
               │ Fetch REST                                          │ Queries / RLS
               └──────────────────────┐       ┌──────────────────────┘
                                      ▼       ▼
                            ┌────────────────────────────┐
                            │      Supabase Cloud        │
                            │   (Postgres, Auth, RLS)    │
                            └────────────────────────────┘
```

| Subdomain / Domain | Target Komponen | Platform | Biaya |
| :--- | :--- | :--- | :--- |
| `alurproject.web.id` | Frontend Web (Next.js App) | Vercel (Project: `alur-web`) | **Rp 0** |
| `www.alurproject.web.id` | Redirect ke `alurproject.web.id` | Vercel (Project: `alur-web`) | **Rp 0** |
| `api.alurproject.web.id` | REST API & LangGraph Agents (FastAPI) | Vercel (Project: `alur-backend`) | **Rp 0** |
| Native Mobile (APK/iOS) | Client Flutter (HTTP API Client) | Local / GitHub Releases | **Rp 0** |
| Database & Auth | PostgreSQL + Row Level Security | Supabase Free-Tier | **Rp 0** |

---

## 2. Bagian A — Konfigurasi & Deployment Backend (FastAPI)

### 2.1 File Konfigurasi di Repositori
FastAPI dideploy sebagai serverless function Python di Vercel menggunakan konfigurasi berikut:

1. **`vercel.json` (di root repositori)**:
   ```json
   {
     "version": 2,
     "builds": [
       {
         "src": "backend/app/main.py",
         "use": "@vercel/python"
       }
     ],
     "routes": [
       {
         "src": "/(.*)",
         "dest": "backend/app/main.py"
       }
     ]
   }
   ```
2. **`requirements.txt` (di root dan di `backend/`)**:
   Berisi seluruh dependensi runtime Python:
   ```text
   fastapi>=0.110.0,<1.0.0
   uvicorn[standard]>=0.28.0,<1.0.0
   pydantic>=2.6.0,<3.0.0
   pydantic-settings>=2.2.0,<3.0.0
   python-dotenv>=1.0.0
   supabase>=2.3.0,<3.0.0
   httpx>=0.27.0,<1.0.0
   langchain-core>=0.3.0
   langchain-google-genai>=2.0.0
   langchain-groq>=0.2.0
   langgraph>=0.2.0
   ```
3. **CORS Configuration di `backend/app/main.py`**:
   Sudah disetel untuk menerima request dari domain web Anda dan mobile:
   ```python
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["*"],  # Atau dibatasi ke ["https://alurproject.web.id", "http://localhost:3000"]
       allow_credentials=True,
       allow_methods=["*"],
       allow_headers=["*"],
   )
   ```

### 2.2 Langkah Setup di Dashboard Vercel (Project 1: `alur-backend`)
1. Buka [vercel.com](https://vercel.com) $\rightarrow$ Login via GitHub.
2. Klik **Add New...** $\rightarrow$ **Project**.
3. Pilih repository **`alur-project`**.
4. Konfigurasi Project:
   - **Project Name**: `alur-backend`
   - **Framework Preset**: `Other`
   - **Root Directory**: `./` (biarkan root agar membaca `vercel.json`)
5. Buka accordion **Environment Variables**, tambahkan:
   - `PUBLIC_SUPABASE_URL` = `https://iajqnfcpljkwhvbicylh.supabase.co`
   - `PUBLIC_SUPABASE_ANON_KEY` = `(anon_key dari Supabase)`
   - `SUPABASE_SERVICE_ROLE_KEY` = `(service_role_key dari Supabase)`
   - `GEMINI_API_KEY` = `(Google AI Studio Gemini API Key)`
   - `GROQ_API_KEY` = `(Groq API Key)`
   - `BACKEND_ENV` = `production`
6. Klik **Deploy**.

### 2.3 Menghubungkan Subdomain `api.alurproject.web.id`
1. Setelah deployment sukses, buka **Settings** $\rightarrow$ **Domains** pada project `alur-backend`.
2. Masukkan domain: `api.alurproject.web.id` $\rightarrow$ klik **Add**.
3. Buka DNS Management registrar domain Anda (Cloudflare / Niagahoster / Domainesia / Rumahweb / dll), tambahkan record DNS:
   - **Type**: `CNAME`
   - **Name / Host**: `api`
   - **Target / Value**: `cname.vercel-dns.com`
   - **TTL**: `Auto` / `3600`
4. Tunggu verifikasi DNS (1–5 menit). Vercel akan otomatis menerbitkan SSL HTTPS gratis.
5. Verifikasi di browser:
   - `https://api.alurproject.web.id/health` $\rightarrow$ `{"status":"healthy","service":"alur-backend","environment":"production"}`
   - `https://api.alurproject.web.id/docs` $\rightarrow$ Tampilan Swagger OpenAPI interaktif.

---

## 3. Bagian B — Konfigurasi & Deployment Web Frontend (Next.js)

### 3.1 Struktur Direktori Web (`web/`)
Folder `web/` dirancang menggunakan Next.js App Router (TypeScript + Tailwind CSS) sesuai prinsip antarmuka *Quiet Monochrome Workspace* di `_docs/DESIGN.md`:

```
web/
├── app/
│   ├── layout.tsx         # Root layout (Theme provider & fonts)
│   ├── page.tsx           # Weekly view utama (7-day accordion)
│   ├── globals.css        # Tailwind directives & CSS color tokens
│   └── components/
│       ├── DayBlock.tsx   # Komponen blok hari (accordion)
│       ├── TaskRow.tsx    # Baris task + checkbox + strikethrough
│       └── BrainDumpModal.tsx # Dialog input bebas / speech-to-text
├── lib/
│   ├── api.ts             # REST client terhubung ke https://api.alurproject.web.id
│   └── supabase.ts        # Supabase client auth
├── package.json
├── tailwind.config.ts     # Palet monokrom: #FAF9F7 (Off-White), #111111 (Ink)
├── tsconfig.json
└── next.config.mjs
```

### 3.2 File Konfigurasi Next.js (`web/next.config.mjs`)
Jika Anda ingin me-rewrite pemanggilan API secara internal (agar frontend bisa memanggil `/api/*` secara transparan tanpa isu CORS):
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: process.env.BACKEND_API_URL 
          ? `${process.env.BACKEND_API_URL}/:path*`
          : 'https://api.alurproject.web.id/:path*',
      },
    ];
  },
};

export default nextConfig;
```

### 3.3 Konfigurasi Environment Variable Frontend (`web/.env.production`)
Di Next.js, variabel yang dapat diakses browser harus diawali `NEXT_PUBLIC_`:
```env
NEXT_PUBLIC_API_URL=https://api.alurproject.web.id
NEXT_PUBLIC_SUPABASE_URL=https://iajqnfcpljkwhvbicylh.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
```

### 3.4 Langkah Setup di Dashboard Vercel (Project 2: `alur-web`)
1. Di dashboard Vercel, klik **Add New...** $\rightarrow$ **Project**.
2. Pilih kembali repository yang sama: **`alur-project`**.
3. Konfigurasi Project:
   - **Project Name**: `alur-web`
   - **Framework Preset**: `Next.js`
   - **Root Directory**: Klik **Edit** $\rightarrow$ pilih folder **`web`** $\rightarrow$ Simpan.
4. Buka accordion **Environment Variables**, tambahkan:
   - `NEXT_PUBLIC_API_URL` = `https://api.alurproject.web.id`
   - `NEXT_PUBLIC_SUPABASE_URL` = `https://iajqnfcpljkwhvbicylh.supabase.co`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = `(anon_key dari Supabase)`
5. Klik **Deploy**.

### 3.5 Menghubungkan Domain Utama `alurproject.web.id`
1. Buka **Settings** $\rightarrow$ **Domains** pada project `alur-web`.
2. Masukkan domain: `alurproject.web.id`.
3. Vercel akan menyarankan penambahan domain redirect: `www.alurproject.web.id` (Pilih opsi redirect ke `alurproject.web.id`).
4. Atur DNS pada registrar domain Anda:
   - **Apex Domain (`@`)**:
     - **Type**: `A`
     - **Name / Host**: `@`
     - **Target / IP**: `76.76.21.21` *(Vercel Anycast IP)*
   - **Subdomain (`www`)**:
     - **Type**: `CNAME`
     - **Name / Host**: `www`
     - **Target / Value**: `cname.vercel-dns.com`
5. Vercel memverifikasi koneksi dan otomatis menerbitkan sertifikat SSL.

---

## 4. Bagian C — Ringkasan Setting DNS Registrar

Tabel seluruh DNS Records yang perlu dimasukkan pada panel domain `alurproject.web.id`:

| Type | Name / Host | Target / Value | Keterangan |
| :--- | :--- | :--- | :--- |
| **CNAME** | `api` | `cname.vercel-dns.com` | Mengarah ke Backend FastAPI (`alur-backend`) |
| **A** | `@` (root) | `76.76.21.21` | Mengarah ke Frontend Web Next.js (`alur-web`) |
| **CNAME** | `www` | `cname.vercel-dns.com` | Redirect otomatis ke domain utama |

> **Catatan jika menggunakan Cloudflare DNS**:  
> Saat pertama kali menambahkan domain di Vercel, ubah icon Cloudflare Proxy menjadi **DNS Only (abu-abu)** selama 2-5 menit agar Vercel dapat menerbitkan sertifikat SSL Let's Encrypt. Setelah status di Vercel valid (centang hijau), Anda bebas mengaktifkan kembali Proxied (oranye) jika diinginkan.

---

## 5. Bagian D — Otomasi Cron Tanpa Server (Fase 3 di Vercel)

Karena Vercel serverless tidak memiliki proses background yang berjalan terus-menerus, tugas terjadwal (cron) dapat dieksekusi secara otomatis dan **100% gratis** menggunakan salah satu opsi berikut:

### Opsi 1: cron-job.org (Gratis, Paling Praktis)
1. Buat akun di [cron-job.org](https://cron-job.org).
2. Tambahkan 3 cron job yang memanggil endpoint backend Anda:
   - **Nightly Status Check** (setiap 00:00 WIB):  
     `POST https://api.alurproject.web.id/debug/run-cron/nightly-status-check`
   - **Weekly Reflection** (Minggu 21:00 WIB):  
     `POST https://api.alurproject.web.id/debug/run-cron/weekly-reflection`
   - **Weekly Recurrence Generator** (Minggu 22:00 WIB):  
     `POST https://api.alurproject.web.id/debug/run-cron/weekly-recurrence`

### Opsi 2: Vercel Cron Jobs (Bawaan `vercel.json`)
Vercel memiliki fitur Cron bawaan (gratis 1 job per project pada tier Hobby) dengan menambahkan konfigurasi cron di `vercel.json`:
```json
{
  "crons": [
    {
      "path": "/debug/run-cron/nightly-status-check",
      "schedule": "0 17 * * *" 
    }
  ]
}
```
*(Catatan: Jam di Vercel cron mengikuti zona waktu UTC, 17:00 UTC = 00:00 WIB).*

---

## 6. Bagian E — Konfigurasi Client Mobile Flutter

Untuk mengarahkan aplikasi Flutter (Android / iOS / Windows Desktop) ke backend yang telah dideploy di Vercel:

1. **Jalankan saat compile / run**:
   ```powershell
   flutter run --dart-define=BACKEND_URL=https://api.alurproject.web.id
   ```
2. **Build Release APK**:
   ```powershell
   flutter build apk --release --dart-define=BACKEND_URL=https://api.alurproject.web.id
   ```
   File APK hasil build berada di `mobile/build/app/outputs/flutter-apk/app-release.apk` dan siap dipasang langsung di smartphone tanpa melalui Google Play Console.
