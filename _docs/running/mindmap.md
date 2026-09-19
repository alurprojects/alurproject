# Peta Konsep dan Alur Sistem ALUR

Dokumen ini memuat rangkuman visual dari struktur proyek ALUR, yang meliputi struktur fitur utama, integrasi platform, serta orkestrasi LLM (LangGraph), dan alur pipeline data.

## 1. Mindmap: Struktur Fitur, Integrasi, dan LLM

Diagram berikut memetakan komponen utama dalam ekosistem ALUR:

```mermaid
flowchart LR
    Root["ALUR Project"]
    
    Feat["Core Features"]
    Root --> Feat
    Feat --> F1["Hybrid To-do (Daily/Weekly)"]
    Feat --> F2["Chat Room (Brain-dump & Curhat)"]
    Feat --> F3["Calendar (Time-block View)"]
    Feat --> F4["Profile & Goals"]
    
    Plat["Platform Integration"]
    Root --> Plat
    Plat --> P1["Mobile App (Flutter)"]
    Plat --> P2["Web App (Next.js - Limited Scope)"]
    Plat --> P3["Backend API (FastAPI)"]
    Plat --> P4["DB, Auth, pg_cron (Supabase)"]
    
    AI["AI & LLM Orchestration"]
    Root --> AI
    AI --> A1["LangGraph (State Machine)"]
    AI --> A2["Companion Agent (Adaptive 2-Tone: HONEST/GENTLE)"]
    AI --> A3["Extractor Agent (Task Parsing)"]
    AI --> A4["Scheduler Agent (Capacity Planning)"]
    AI --> A5["Reflection Agent (Insights & Patterns)"]
```

## 2. Flowchart: Pipeline Data dan Proses Sistem Utama

Diagram alir berikut menunjukkan bagaimana data bergerak dari interaksi pengguna (di Mobile/Web) masuk ke backend FastAPI, diproses oleh agen AI dalam LangGraph, serta bagaimana cron job di latar belakang menyatukan data untuk analisis refleksi.

```mermaid
flowchart TD
    User(["User"])
    Client["Client App (Mobile/Web)"]
    API["FastAPI Backend"]
    DB[("Supabase DB")]
    Cron["pg_cron (Supabase)"]
    
    subgraph LG ["LangGraph AI Pipeline"]
        direction TB
        Comp["Companion Agent"]
        Intent{"Intent Routing"}
        Ext["Extractor Agent"]
        Sched["Scheduler Agent"]
        Refl["Reflection Agent"]
    end

    %% User Interaction Flow
    User -->|"1. Kirim Pesan / Brain-dump"| Client
    Client -->|"2. POST /chat/message"| API
    API -->|"3. Inisiasi State Graph"| Comp
    
    %% Companion Processing
    DB -.->|"Baca Konteks Historis"| Comp
    Comp -->|"4. Analisis Intent & Tone (HONEST/GENTLE)"| Intent
    
    %% Routing
    Intent -->|"TASK_CAPTURE"| Ext
    Intent -->|"REFLECTION / CHAT"| API
    
    %% Task Extraction Flow
    Ext -->|"5. Parsing Teks menjadi Task"| Sched
    Sched -->|"6. Jadwalkan & Cek Kapasitas"| API
    
    %% Persistence and Response
    API -->|"7. Simpan tasks / conversation_logs"| DB
    API -->|"8. Kembalikan Respon AI & State Baru"| Client
    Client -->|"9. Perbarui UI"| User
    
    %% Cron Background Flow
    Cron -->|"A. Pemicu Otomatis (Nightly/Weekly)"| API
    API -->|"B. POST /internal/cron/* (X-Cron-Secret)"| Refl
    DB -.->|"C. Batching Fetch Data (tasks + logs)"| Refl
    Refl -->|"D. Hasilkan ai_insights & Flag Missed Tasks"| DB
```

## 3. Alur Penggunaan Fitur (User Journey)

Bagian ini menjabarkan bagaimana setiap fitur inti digunakan dari sudut pandang pengguna sehari-hari dengan bahasa yang mudah dipahami.

### A. Fitur To-Do (Eksekusi Harian & Mingguan)
Fokus utama pengguna untuk mengeksekusi tugas tanpa disibukkan dengan terlalu banyak informasi visual.

```mermaid
flowchart LR
    Start([Buka Tab To-do]) --> View[Tampilan 'Daily Focus' / Hari Ini]
    View --> Swipe[Swipe Kiri/Kanan]
    Swipe --> ViewOther[Lihat Tugas Hari Lain]
    
    View --> Check[Centang Checkbox]
    Check --> Done((Tugas Selesai))
    
    View --> Add[Tap '+ Add Task']
    Add --> Manual[Ketik & Tambah Manual]
    
    View --> Toggle[Toggle 'Weekly Overview']
    Toggle --> Expand[Lihat Jadwal Penuh Senin-Minggu]
```

### B. Fitur Brain-dump (Ekstraksi Tugas Otomatis)
Mengubah pikiran acak dan tumpukan ide mentah langsung menjadi daftar tugas terstruktur melalui percakapan biasa.

```mermaid
sequenceDiagram
    actor User
    participant App as Tab Chat Room
    participant AI as AI (Companion & Extractor)
    
    User->>App: "Besok sore aku harus email bos, trus beli cat buat pagar"
    App->>AI: Menganalisis pesan (Sistem mendeteksi 2 pekerjaan)
    AI->>AI: Memecah jadi "Email bos" (besok) & "Beli cat" (hari ini)
    AI-->>App: Balas: "Siap! 2 tugas baru sudah masuk ke daftar To-Do kamu."
    App-->>User: Tampilkan pesan + Otomatis update daftar To-Do
```

### C. Fitur Curhat & Cek Kapasitas Beban Kerja
Saat pengguna merasa kewalahan, Chat Room berubah menjadi asisten empati yang secara aktif mengecek sisa energi pengguna.

```mermaid
sequenceDiagram
    actor User
    participant App as Tab Chat Room
    participant AI as AI (Companion Agent)
    
    User->>App: "Aku capek banget nih, apalagi sih kerjaan yang sisa hari ini?"
    App->>AI: Membaca teks & mengecek beban kerja minggu ini
    AI->>AI: Mendeteksi indikasi 'burnout' (Beralih ke mode bicara GENTLE)
    AI-->>App: Balas: "Hari ini masih sisa 3 tugas, tapi kamu kelihatan lelah. Mau aku undur semuanya ke besok aja biar kamu bisa istirahat?"
    App-->>User: Menampilkan tawaran reschedule & simpati AI
```

### D. Fitur Evaluasi Otomatis (Review Malam & Mingguan)
Sistem merapikan tugas-tugas secara diam-diam di latar belakang agar pengguna selalu mendapat rekomendasi yang jujur dan realistis.

```mermaid
flowchart TD
    Start([Pukul 00:00 - Setiap Malam]) --> Cek[Sistem Mengecek Tugas Hari Ini]
    Cek --> Sisa[Ada Tugas Belum Dicentang]
    Sisa --> Missed[Tugas Ditandai 'Terlewat' / MISSED]
    Missed --> Ask[Besoknya AI bertanya di Chat: 'Kemarin lupa atau sengaja dilewati?']
    
    Start2([Minggu Malam - Tiap Pekan]) --> Refl[AI Evaluasi Data Seminggu]
    Refl --> Combine[Membaca Pola: Daftar tugas MISSED + Riwayat chat]
    Combine --> Insight[Hasilkan 'AI Insights' peringatan beban kerja]
```

---
**Catatan Penting:** 
Dokumentasi ini merangkum spesifikasi ALUR agar mudah dipahami secara visual, dengan berpegang teguh pada pendekatan arsitektur "Backend-Heavy & Simple Frontend", di mana orkestrasi *state* dan kecerdasan sepenuhnya terpusat pada multi-agent LangGraph.
