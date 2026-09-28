# ALUR — Deployment & Infrastructure Guide

> [!NOTE]
> **Status Deployment: Rencana Bertahap (Governing Decision)**
> Dokumen ini saat ini menggunakan **Vercel Free-Tier (Tahap 1)** secara penuh. Jika batas 10 detik mulai sering tercapai, backend akan dimigrasikan ke **Cloudflare Workers Free-Tier (Tahap 2)** (hanya jika modul AI bisa diadaptasi tanpa LangGraph), dan terakhir ke **VPS Berbayar (Tahap 3)** jika batasan tahap sebelumnya tak dapat dihindari. Frontend Web (Next.js) tetap di Vercel.

Dokumen ini adalah panduan teknis operasional (*step-by-step*) untuk mengonfigurasi, mendeploy, dan mengintegrasikan **Backend (FastAPI)** dan **Web Frontend (Next.js)** ke platform **Vercel** dengan domain kustom **`alurproject.web.id`**, beroperasi pada **100% Free-Tier (Zero Credit Card Required)**.

---

## 1. Topologi Domain & Arsitektur Sistem

```text
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

## 2. Bagian A — Konfigurasi & Deployment Backend (FastAPI) di Vercel (Tahap 1)

Backend FastAPI dideploy sebagai **Serverless Function Python** di Vercel. 

> [!WARNING]
> **Limitasi 10 Detik Vercel Hobby Tier:** Vercel gratis memiliki batas waktu eksekusi maksimal 10 detik per request. AI dan LangGraph harus dioptimasi agar merespons di bawah batas ini. Pastikan Anda menggunakan LLM super cepat seperti **Groq**. 

### 2.0 Kapan Pindah ke Tahap 2/3?
*Pindah kalau endpoint `/chat/message` ATAU `/internal/cron/reflection` mulai return 504 Gateway Timeout secara konsisten (bukan sesekali) — pantau lewat log/observability Section 10 `technical.md`.*

### 2.1 File Konfigurasi di Repositori
FastAPI dikonfigurasi untuk Vercel Serverless melalui `vercel.json` di root repositori:

1. **`vercel.json`**:
   ```json
   {
     "version": 2,
     "rewrites": [
       {
         "has": [
           {
             "type": "host",
             "value": "api.alurproject.web.id"
           }
         ],
         "source": "/(.*)",
         "destination": "/api/index.py"
       },
       {
         "source": "/api/(.*)",
         "destination": "/api/index.py"
       }
     ]
   }
   ```
2. **`requirements.txt` (di `backend/`)**:
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
   ```python
   app.add_middleware(
       CORSMiddleware,
       allow_origins=[
           "https://alurproject.web.id",
           "https://www.alurproject.web.id",
           "http://localhost:3000",   # dev Next.js
       ],
       allow_credentials=True,
       allow_methods=["*"],
       allow_headers=["*"],
   )
   ```

### 2.2 Langkah Setup di Dashboard Vercel
1. Di Vercel Dashboard, klik **Add New...** → **Project**.
2. Pilih repository GitHub ALUR Anda.
3. Konfigurasi Project:
   - **Project Name**: `alur-backend`
   - **Framework Preset**: `Other`
   - **Root Directory**: Biarkan *default* (`./`)
4. Buka accordion **Environment Variables**, tambahkan rahasia server (disalin dari `.env`):
   - `PUBLIC_SUPABASE_URL` = `https://iajqnfcpljkwhvbicylh.supabase.co`
   - `PUBLIC_SUPABASE_ANON_KEY` = `(anon_key)`
   - `SUPABASE_SERVICE_ROLE_KEY` = `(service_role_key)`
   - `GEMINI_API_KEY` = `(key)`
   - `GROQ_API_KEY` = `(key)`
   - `CRON_SECRET` = `(secret acak untuk validasi cron)`
   - `BACKEND_ENV` = `production`
5. Klik **Deploy**.

### 2.3 Menghubungkan Subdomain `api.alurproject.web.id`
1. Setelah deploy selesai, buka tab **Settings** → **Domains** di project `alur-backend`.
2. Masukkan domain `api.alurproject.web.id`.
3. Atur DNS pada panel domain registrar Anda (lihat Ringkasan Setting DNS di Bagian C). Vercel akan memverifikasi dan menerbitkan SSL otomatis.

---

## 3. Bagian B — Konfigurasi & Deployment Web Frontend (Next.js)

### 3.1 Struktur Direktori Web (`web/`)
Folder `web/` dirancang menggunakan Next.js App Router (TypeScript + Tailwind CSS) sesuai prinsip antarmuka *Quiet Monochrome Workspace* di `_docs/DESIGN.md`:

```
web/
├── app/
│   ├── layout.tsx         # Root layout (Theme provider & fonts)
│   ├── page.tsx           # Hybrid Daily/Weekly view (sinkron dengan PRD.md Section 3.2)
│   ├── globals.css        # Tailwind directives & CSS color tokens
│   └── components/
│       ├── DayBlock.tsx   # Komponen blok hari (accordion/daily focus)
│       ├── TaskRow.tsx    # Baris task + checkbox + strikethrough
│       └── CalendarView.tsx  # Komponen calendar time-block (read-only)
├── lib/
│   ├── api.ts             # REST client terhubung ke https://api.alurproject.web.id
│   └── supabase.ts        # Supabase client auth
├── package.json
├── tailwind.config.ts     # Token warna disinkronkan dari _docs/DESIGN.md (#FAF9F7, #111111, #F0EFED)
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

Tabel seluruh DNS Records yang dimasukkan pada panel domain `alurproject.web.id`:

| Type | Name / Host | Target / Value | Keterangan |
| :--- | :--- | :--- | :--- |
| **A** | `@` atau `alurproject.web.id` | `76.76.21.21` *(Atau IP persis yang tertera di Vercel)* | Mengarah ke Frontend Web Next.js (`alur-web`) |
| **CNAME** | `api` | `cname.vercel-dns.com` *(Atau sesuai instruksi Vercel)* | Mengarah ke Backend FastAPI (`alur-backend`) di Vercel |
| **CNAME** | `www` | `cname.vercel-dns.com` *(Atau sesuai instruksi Vercel)* | Redirect otomatis ke domain utama |

> **Catatan Penting mengenai Nilai CNAME & IP**:
> 1. **Vercel Dynamic Verification**: Vercel saat ini dapat memberikan CNAME unik berbasis hash (seperti `...vercel-dns-017.com`) untuk verifikasi keamanan domain otomatis. **Selalu gunakan nilai persis yang ditampilkan di Vercel Dashboard $\rightarrow$ Settings $\rightarrow$ Domains** untuk `alur-web` maupun `alur-backend`.
> 2. **Target CNAME untuk `www`**: Ketika Anda menambahkan `www.alurproject.web.id` di project `alur-web`, Vercel akan otomatis menyarankan opsi *"Redirect to alurproject.web.id"*. Masukkan nilai CNAME yang diminta oleh Vercel pada form DNS registrar Anda.
> 3. **Catatan jika menggunakan Cloudflare DNS**:
>    Saat pertama kali menambahkan domain di Vercel, ubah icon Cloudflare Proxy menjadi **DNS Only (abu-abu)** selama 2-5 menit agar Vercel dapat menerbitkan sertifikat SSL Let's Encrypt. Setelah status di Vercel valid (centang hijau), Anda bebas mengaktifkan kembali Proxied (oranye) jika diinginkan.

---

## 4.1 Troubleshooting: "This page doesn't exist" (404 NOT_FOUND)

Jika saat mengakses `https://alurproject.web.id` muncul halaman hitam Vercel bertuliskan *"This page doesn't exist / 404 NOT_FOUND"*:
- **Penyebab**: Kode server Vercel aktif, namun project `alur-web` di Vercel belum memiliki deployment yang berhasil, atau file folder `web/` di GitHub masih kosong karena belum di-push dari komputer lokal.
- **Solusi**:
  1. Jalankan `git status` di komputer lokal untuk memastikan folder `web/` sudah ter-commit.
  2. Jalankan `git add .`, `git commit -m "feat: deploy web"`, dan `git push origin main`.
  3. Buka dashboard Vercel pada project **`alur-web`** $\rightarrow$ tab **Deployments**.
  4. Pastikan deployment terbaru berstatus **Ready (Hijau)**.
  5. Begitu deployment Ready, refresh `https://alurproject.web.id` dan halaman Weekly Planner ALUR akan langsung tampil.

---

## 5. Bagian D — Otomasi Cron

Tugas terjadwal (cron) dieksekusi via layanan eksternal yang memanggil endpoint internal backend.

> [!IMPORTANT]
> Semua endpoint cron berada di path `/internal/cron/*` dan WAJIB menyertakan header `X-Cron-Secret: <nilai dari env CRON_SECRET>`. Request tanpa header ini → 401 Unauthorized.

### cron-job.org (Gratis, Paling Praktis)
1. Buat akun di [cron-job.org](https://cron-job.org).
2. Tambahkan cron job berikut. Pada setiap job, buka tab **Advanced** → **Headers** → tambahkan custom header:
   - **Header Name**: `X-Cron-Secret`
   - **Header Value**: *(sama dengan nilai `CRON_SECRET` di env backend)*

3. Daftar cron jobs:
   - **Nightly Status Check** (setiap 00:00 WIB / 17:00 UTC):
     `POST https://api.alurproject.web.id/internal/cron/nightly-status-check`
   - **Weekly Reflection** (Minggu 21:00 WIB / 14:00 UTC):
     `POST https://api.alurproject.web.id/internal/cron/weekly-reflection`
   - **Weekly Recurrence Generator** (Minggu 22:00 WIB / 15:00 UTC):
     `POST https://api.alurproject.web.id/internal/cron/weekly-recurrence`
   - **Keep-Alive / Cold Start Prevention** (setiap 10 menit, opsional):
     `GET https://api.alurproject.web.id/health`

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
