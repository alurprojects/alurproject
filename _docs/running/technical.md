# Technical Specification: ALUR

Dokumen ini berisi spesifikasi teknis untuk pengembangan aplikasi ALUR. ALUR didesain dengan pendekatan backend-heavy di mana orkestrasi AI, *state management*, dan logika kompleks berjalan di sisi *server*, sementara *frontend* (Mobile & Web) dipertahankan sesimpel mungkin.

Aplikasi ini menargetkan pengguna berusia 18-35 tahun yang membutuhkan produktivitas secara umum, dengan fitur utama yang terpusat pada Chat Room (*brain-dump* diperluas) dan Hybrid To-do.

---

## 1. Stack Overview

| Layer | Teknologi | Alasan |
|---|---|---|
| **Mobile App** | Flutter (Dart) | Satu basis kode (codebase) untuk Android dan iOS, pengembangan cepat. |
| **Web App** | Next.js (TypeScript, Tailwind CSS) | Standar industri untuk *webapp* modern, performa tinggi, dan mudah di-*deploy*. |
| **Backend API** | FastAPI (Python) | Dukungan *async*, sangat cocok dan *native* untuk integrasi LangChain/LangGraph. |
| **Database** | Supabase (PostgreSQL) | Solusi *all-in-one*: Auth, Database (PostgreSQL), Row Level Security (RLS), dan `pg_cron`. |
| **Auth** | Supabase Auth (Google OAuth) | Sistem *zero password*, *frictionless onboarding* menggunakan akun Google. |
| **AI Orchestration** | LangGraph | Mengelola *state machine* dan alur logika antar-*agent* AI. |
| **Agent Runtime** | LangChain | *Wrapper* standar untuk pemanggilan prompt/LLM per *node* dalam ekosistem. |
| **LLM Provider** | Gemini 2.0 Flash (primary), Groq (fallback) | Keseimbangan antara biaya (murah) dan performa/kecepatan respons (fast). |
| **Scheduled Jobs** | Supabase `pg_cron` + Edge Functions | Eksekusi *job* otomatis untuk *nightly reflection* dan *weekly planning*. |
| **Voice-to-Text** *(Fase 3)* | Gemini Audio API / Whisper | Mendukung input *brain-dump* via suara di masa mendatang. |
| **Google Calendar** *(Tahap B)* | OAuth 2.0 REST, `calendar.readonly` | Membaca *events* (*read-only*) untuk mengkalkulasi waktu kosong. |
| **Deployment** | Vercel Free-Tier (Sementara / MVP) | *Hosting* 100% Serverless. **Catatan:** Solusi sementara sebelum migrasi ke VPS, karena batas eksekusi Vercel 10 detik. |

---

## 2. Arsitektur Sistem

Secara arsitektural, klien berinteraksi dengan API yang disediakan oleh FastAPI. Otentikasi dan *database* didelegasikan langsung atau melalui *backend* ke Supabase. Logika inti dari aplikasi berpusat di Chat Room, di mana setiap pesan akan memicu *pipeline* LangGraph.

```mermaid
flowchart TD
    subgraph Clients
        F[Flutter App\nMobile]
        W[Next.js App\nWeb]
    end

    subgraph Backend FastAPI
        API[API Router]
        Auth[/auth]
        Tasks[/tasks]
        Chat[/chat]
        BrainDump[/brain-dump\nLegacy]
        Insights[/insights]
        
        API --> Auth
        API --> Tasks
        API --> Chat
        API --> BrainDump
        API --> Insights
    end

    subgraph LangGraph Pipeline
        Companion[Companion Agent]
        Extractor[Extractor Agent]
        Validate[Validate Ambiguity]
        Scheduler[Scheduler Agent]
        Reflection[Reflection Agent\nFase 3]
        
        Chat --> Companion
        BrainDump --> Companion
        Companion -->|Task Capture| Extractor
        Companion -->|Chat/Reflection| Respond
        Extractor --> Validate
        Validate --> Scheduler
        Scheduler --> Respond[Format Response]
    end

    subgraph Supabase
        DB[(PostgreSQL)]
        RLS{Row Level Security}
        Cron(pg_cron)
        S_Auth(Supabase Auth)
    end

    Clients --> API
    
    Auth --> S_Auth
    Tasks --> DB
    Insights --> DB
    Respond --> DB
    
    Cron -->|Trigger| Reflection
    DB --- RLS
```

**Aliran Utama:**
1. Pengguna login via **Supabase Auth**.
2. Pengguna mengirim pesan di Chat Room (`/chat`).
3. Pesan masuk ke **Companion Agent** (LangGraph).
4. Companion Agent menentukan intent pesan. Jika ada *actionable task*, dialihkan ke **Extractor Agent**.
5. Extractor Agent mengekstrak tugas dan **Validate Ambiguity** memeriksa kelengkapannya.
6. **Scheduler Agent** menempatkan tugas ke dalam To-do list harian (berdasarkan kalkulasi kapasitas) lalu disimpan di **Supabase**.
7. Respons final dikembalikan ke pengguna di antarmuka Chat Room.

---

## 3. Struktur Repo

Kode diatur dalam *monorepo* atau repositori terpisah berdasarkan arsitektur komponen.

```text
alur/
├── mobile/                 # Frontend Flutter
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   └── theme/
│   │   ├── models/
│   │   ├── services/
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   ├── todo/       # Hybrid Daily/Weekly view
│   │   │   ├── chat/       # Chat Room interface
│   │   │   ├── calendar/
│   │   │   ├── profile/
│   │   │   └── main_screen.dart
│   │   └── widgets/
│   └── pubspec.yaml
├── web/                    # Frontend Next.js (Scope awal: To-do + Calendar ONLY)
│   ├── app/
│   │   ├── components/
│   │   │   ├── DayBlock.tsx
│   │   │   ├── TaskRow.tsx
│   │   │   └── CalendarView.tsx
│   │   ├── layout.tsx
│   │   ├── page.tsx       # Hybrid Daily/Weekly view
│   │   └── globals.css
│   ├── lib/
│   │   ├── api.ts
│   │   └── supabase.ts
│   ├── tailwind.config.ts # Token warna disinkronkan dari DESIGN.md
│   └── package.json
├── backend/                # FastAPI Backend
│   ├── app/
│   │   ├── api/
│   │   │   ├── tasks.py
│   │   │   ├── chat.py     # NEW: Chat Room endpoints
│   │   │   ├── brain_dump.py
│   │   │   └── insights.py
│   │   ├── agents/
│   │   │   ├── companion.py # NEW: Companion/Curhat Agent
│   │   │   ├── extractor.py
│   │   │   ├── scheduler.py
│   │   │   ├── reflection.py
│   │   │   └── graph.py
│   │   ├── core/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── services/
│   │   └── main.py
│   ├── cron/
│   └── requirements.txt
└── _docs/                  # Dokumentasi Teknis
```

---

## 4. API Contract

Seluruh komunikasi API memerlukan *header* otentikasi.
**Header:** `Authorization: Bearer <supabase_jwt>`

### Tasks
- `GET /tasks?date={YYYY-MM-DD}` (atau `?week={YYYY-Www}`) — Mengambil daftar task. Mendukung *query* untuk tampilan *daily* maupun *weekly*.
- `POST /tasks` — Membuat task secara manual.
- `PATCH /tasks/{id}` — *Toggle status* task (Selesai/Belum).
- `PATCH /tasks/{id}/clarify` — Memberikan jawaban untuk *clarification prompt* dari AI.
- `PATCH /tasks/{id}/follow-up` — Memberikan respon atas *follow-up* AI pada tugas yang tidak selesai.
- `PATCH /tasks/{id}/reschedule` — Menjadwalkan ulang tugas secara manual.

### Chat & Interaction (Utama)
- `POST /chat/message` — **[NEW]** Mengirim pesan dari pengguna ke Chat Room. Memanggil orkestrasi AI LangGraph. Merespons dengan balasan AI dan *state* perubahan (misal: *task created*).
- `GET /chat/history?date={YYYY-MM-DD}` — **[NEW]** Mendapatkan riwayat percakapan pada hari tertentu.
- `POST /brain-dump` — *(Legacy)* Secara internal di-*route* ke *pipeline* Chat Room.
- `GET /insights?surfaced=true` — Membaca data *insight* refleksi/AI.

### Chat History & Data Retention
- `DELETE /chat/history` — Hapus seluruh riwayat chat user yang memanggilnya. Butuh `Authorization: Bearer <supabase_jwt>`. Destruktif dan tidak bisa di-undo.
- `GET /chat/history/pending-deletion` — Daftar log chat yang mendekati batas retensi otomatis (`pending_deletion_notified_at IS NOT NULL`). Untuk ditampilkan sebagai notice di Profile tab.
- `POST /chat/history/export` — Kembalikan seluruh riwayat chat user sebagai JSON untuk diunduh sebagai backup lokal.
- `PATCH /chat/history/retention-override` — Set `retention_override = TRUE` untuk log yang dipilih user ("Simpan Selamanya"), mengecualikannya dari auto-hapus.

### Calendar (Tahap B)
- `POST /calendar/connect` — Menyimpan dan mengelola token OAuth Google Calendar.
- `GET /calendar/events?date={YYYY-MM-DD}` — Membaca *events* *read-only* dari Google Calendar.

### Internal/Cron Endpoints
- `POST /internal/cron/{job_name}` — Menjalankan job cron secara manual atau otomatis via layanan cron eksternal. **TIDAK menggunakan `Authorization: Bearer <supabase_jwt>`** — endpoint ini memvalidasi header `X-Cron-Secret` sebagai gantinya. Request tanpa header atau dengan nilai salah → 401 Unauthorized. Ini jalur sistem-ke-sistem yang terpisah dari jalur user biasa.

---

## 5. LangGraph Node Detail

Otoritas orkestrasi AI utama di-handle oleh LangGraph. *Graph* ini dimulai dari evaluasi pesan pengguna dan diarahkan berdasarkan klasifikasinya.

```python
from langgraph.graph import StateGraph

# Inisialisasi Graph dengan model State
graph = StateGraph(AlurChatState)

# Definisi Node
graph.add_node("companion", companion_agent)          # Classify & respond
graph.add_node("extractor", extractor_agent)          # Extract tasks if needed  
graph.add_node("validate_ambiguity", validate_fn)     # Rule-based, not LLM
graph.add_node("scheduler", scheduler_agent)          # Place tasks
graph.add_node("respond", format_response)            # Format final response

# Routing: companion memutuskan jalur proses (conditional routing)
graph.add_conditional_edges("companion", route_by_type, {
    "task_capture": "extractor",
    "reflection": "respond",
    "chat": "respond",
    "capacity_query": "respond",
})

# Sequential routing untuk ekstraksi tugas
graph.add_edge("extractor", "validate_ambiguity")
graph.add_edge("validate_ambiguity", "scheduler")
graph.add_edge("scheduler", "respond")
```

**State Model (`AlurChatState`)** menyimpan data konteks sepanjang siklus *graph*:
- `raw_message`: Pesan asli pengguna.
- `user_id`: Identifikasi *user*.
- `message_type`: Klasifikasi hasil Companion Agent.
- `draft_tasks`: *List* tugas hasil ekstraksi (jika ada).
- `daily_capacity_hours`: Kalkulasi jam produktif yang tersedia.
- `scheduled_tasks`: Tugas yang sudah diproses oleh *scheduler*.
- `ai_response`: Balasan *text* final.
- `conversation_context`: Riwayat percakapan selama 7 hari terakhir.
- `mood_indicator`: Deteksi *mood* dari sistem adaptif.

---

## 6. Companion Agent Architecture

Companion Agent adalah pintu gerbang (titik kontak pertama) interaksi AI dengan pengguna di Chat Room. 

**Tanggung Jawab Utama:**
1. **Input Processing:** Mengklasifikasikan intent pesan menjadi `TASK_CAPTURE`, `REFLECTION`, `CHAT`, atau `CAPACITY_QUERY`.
2. **Context Awareness:** Agen memiliki memori konteks berdasarkan 20 pesan terakhir, status *tasks* minggu berjalan, dan *recent insights*.
3. **2-Tone Personality System:**
   - **Tone Selection:** 2 nada bicara — `HONEST` (default: lugas, data-driven) dan `GENTLE` (kondisional: dipakai HANYA saat mendeteksi sinyal burnout/overload nyata).
   - **Faktor Pengaruh:** `completion_rate` 7 hari terakhir dan `consecutive_misses` sebagai faktor utama untuk menentukan kapan switch dari HONEST ke GENTLE.
4. **Output:** `{ response_text, message_type, extracted_tasks[], overload_signal, tone_used }`
5. **Memory Management:** Menyimpan dan menarik percakapan historis di tabel `conversation_logs`.

---

## 7. Environment & Secrets

Variabel lingkungan (Environment Variables) yang perlu disiapkan di Backend & *deployment*:
- `SUPABASE_URL` & `SUPABASE_KEY` (Anon / Service Role)
- `GEMINI_API_KEY` (dan `GROQ_API_KEY` untuk *fallback*)
- `GOOGLE_CLIENT_ID` & `GOOGLE_CLIENT_SECRET` (Untuk OAuth & Calendar)
- `COMPANION_SYSTEM_PROMPT` — *(Optional override)* untuk menyesuaikan pedoman inti AI persona.
- `CHAT_CONTEXT_WINDOW_DAYS=7` — Batas waktu memori percakapan untuk *context window*.
- `JWT_SECRET` (Sama dengan Supabase JWT Secret untuk verifikasi *bearer token*).
- `CRON_SECRET` — server-only, dipakai untuk validasi header `X-Cron-Secret` pada endpoint `/internal/cron/*`. Secret ini JUGA dipakai sebagai nilai `app.cron_secret` di `DATABASE.md` Section 11 (`pg_cron` → `net.http_post`) — satu secret yang sama, jangan generate dua nilai berbeda.

---

## 8. Testing Strategy

Strategi pengujian difokuskan pada ketepatan orkestrasi AI dan pengalaman pengguna:

**Backend (Unit & Integration Tests):**
- **Companion Agent:** Pengujian *unit* dengan *dataset* 20+ pesan sampel (campuran curhat, *brain-dump* tugas, dll). *Assert* ketepatan `message_type` yang dihasilkan.
- **Extractor Agent:** Pengujian *parsing* kalimat kompleks (*brain-dump*) menjadi *structured JSON tasks*.
- **Scheduler Agent:** *Overload test* – menguji respons *scheduler* ketika tugas melampaui `daily_capacity`.
- **Chat Room Integration:** Uji alur penuh: `Kirim Pesan` → `Klasifikasi` → `Ekstraksi` → `Penjadwalan`.

**Frontend / Mobile:**
- Uji *Flutter Widgets* untuk 4 Tab utama: To-do, Chat, Calendar, Profile.
- Uji fitur *Hybrid View* (Daily/Weekly) di halaman To-do.

**End-to-End (E2E):**
- Pengguna mengirim pesan "*Besok aku harus beli susu dan ngerjain laporan*".
- Tugas diproses oleh AI dan *widget* To-do langsung memperbarui state memunculkan *checkbox*.
- Pengguna mencentang tugas (status sinkron ke *database*).

---

## 9. Deployment

- **Backend (FastAPI):** Di-*deploy* sebagai _serverless functions_ menggunakan Vercel (Free-Tier). Cocok karena *endpoint* ringan.
- **Web App (Next.js):** Di-*deploy* juga di Vercel.
- **Mobile (Flutter):** Distribusi menggunakan *stores* (Play Store, App Store) atau melalui berkas `.apk` internal.
- **Database:** Sepenuhnya di-kelola oleh Supabase *managed service* (termasuk Cron & Edge functions).
- **Domain:** Semua servis diarahkan di bawah domain/subdomain `alurproject.web.id`.

---

## 10. Observability

Agar sistem dapat dianalisis dan dievaluasi terus-menerus (terutama kualitas agen AI):
- Setiap interaksi ke LLM akan dilog metrik latensi dan biaya token.
- **Expanded Companion Log:** Menyimpan *log* setiap interaksi Companion Agent dengan atribut `message_type`, `tone_used`, dan `mood_detected`.
- Data ini digunakan untuk *quality monitoring* secara manual atau semi-otomatis, memastikan 2-Tone Personality System (HONEST/GENTLE) berfungsi dengan wajar tanpa *hallucination*.
- Memanfaatkan Supabase Dashboard Analytics dan alat APM ringan (jika diaktifkan).

---

## 11. Clean Code Standards

1. **Modular AI:** Logika *prompting* dan agen harus dipisahkan di direktori `backend/app/agents/`.
2. **Directory Structure:** *Frontend/Mobile* wajib mengikuti standar struktur yang rapi (termasuk folder `chat/` untuk memfasilitasi integrasi *Chat Room* baru).
3. **Typing & Schemas:** Gunakan Pydantic (`schemas/`) secara ketat di FastAPI untuk validasi *input/output*, terutama parsing *output* LLM.
4. **State Management (Mobile):** Gunakan pendekatan *state management* (mis. Riverpod atau Provider) untuk menjaga *UI thread* Flutter tetap responsif.
5. **Naming Conventions:** Gunakan *snake_case* untuk file/variabel Python, *camelCase* untuk Dart/TS (kecuali file di Dart yang *snake_case*), dan penamaan *endpoint* API yang representatif dan *RESTful*.
