# DATABASE.md — ALUR: Schema End-to-End

**Platform**: Supabase (PostgreSQL 15+) dengan Row Level Security (RLS), `pg_cron`, dan Supabase Auth.

> [!IMPORTANT]
> Dokumen ini adalah **Single Source of Truth** untuk skema database ALUR. Setiap perubahan schema harus diperbarui di sini terlebih dahulu sebelum dieksekusi sebagai migrasi.

---

## 1. Ringkasan Tabel

| Tabel | Fase | Deskripsi |
| :--- | :---: | :--- |
| `users` | 1 | Profil, timezone, dan kapasitas harian user |
| `goals` | 1 | Target / tujuan jangka menengah-panjang user |
| `tasks` | 1 | Unit kerja utama; bisa manual atau dari brain-dump |
| `task_suggestions` | 3 | Saran reschedule dari Scheduler Agent (histori + status respons) |
| `ai_insights` | 3 | Insight mingguan yang ditulis oleh Reflection Agent |

---

## 2. Diagram Relasi (ERD)

```
users (1)
 ├──────────────────────────────────────────── goals (N)
 │                                               │
 └──────────────────────────────────────────── tasks (N) ─── goal_id → goals (nullable)
                                                  │
                                                  └──────── task_suggestions (N)

users (1) ─────────────────────────────────── ai_insights (N)
```

---

## 3. Tabel: `users`

Diteruskan dari Supabase Auth. Baris dibuat otomatis oleh trigger saat user pertama kali login.

```sql
CREATE TABLE users (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email       TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL DEFAULT '',
    timezone    TEXT NOT NULL DEFAULT 'Asia/Jakarta',   -- contoh: 'America/New_York'
    daily_capacity_hours  NUMERIC(3,1) NOT NULL DEFAULT 8.0, -- jam kerja efektif per hari
    preferences JSONB NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Kolom `preferences` (JSONB)

Struktur yang disepakati untuk disimpan di dalam JSON preferences:

```jsonc
{
  "theme": "dark",                  // "dark" | "light" | "system" (default: "system")
  "language": "id",                 // "id" | "en" (default: "id")
  "week_start": "monday",           // "monday" | "sunday" (default: "monday")
  "notifications": {
    "enabled": true,
    "reminder_hour": 8              // jam pengingat pagi (0–23, default: 8)
  }
}
```

### Index & Trigger

```sql
-- Trigger: update updated_at otomatis
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Trigger: buat baris users dari Supabase Auth saat signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO users (id, email, name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

### Row Level Security (RLS)

```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- User hanya bisa membaca dan mengubah profil dirinya sendiri
CREATE POLICY "users: read own" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users: update own" ON users
    FOR UPDATE USING (auth.uid() = id);
```

---

## 4. Tabel: `goals`

Goal adalah target besar yang bisa di-breakdown menjadi banyak task.

```sql
CREATE TYPE goal_status AS ENUM ('ACTIVE', 'DONE', 'ARCHIVED');

CREATE TABLE goals (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title        TEXT NOT NULL,
    description  TEXT,                    -- konteks untuk AI saat scheduling
    deadline     DATE,                    -- target selesai, nullable
    status       goal_status NOT NULL DEFAULT 'ACTIVE',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Index & Trigger

```sql
CREATE INDEX goals_user_id_idx ON goals (user_id);
CREATE INDEX goals_status_idx ON goals (user_id, status);  -- query "ACTIVE goals milik user"

CREATE TRIGGER goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### Row Level Security (RLS)

```sql
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "goals: all own" ON goals
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

---

## 5. Tabel: `tasks`

Tabel inti. Menangani task manual, brain-dump, task berulang (recurrence), dan alur miss → follow-up.

```sql
CREATE TYPE task_status        AS ENUM ('PENDING', 'DONE', 'MISSED');
CREATE TYPE task_source        AS ENUM ('MANUAL', 'BRAIN_DUMP');
CREATE TYPE missed_follow_up   AS ENUM ('NONE', 'PENDING', 'FORGOT', 'SKIPPED', 'RESCHEDULED');

CREATE TABLE tasks (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal_id             UUID REFERENCES goals(id) ON DELETE SET NULL,  -- nullable

    -- Konten
    title               TEXT NOT NULL,
    estimated_minutes   INT CHECK (estimated_minutes IS NULL OR estimated_minutes > 0),
                                         -- NULL = tampil sebagai "(?)" di UI
    recurrence_rule     TEXT,            -- nullable; format: 'daily' | 'weekdays' | '2x/week'
                                         -- lihat Section 8 untuk panduan format
    recurrence_group_id UUID,            -- nullable; menyatukan semua instance mingguan dari
                                         -- 1 recurring task. Diisi = id task pertama saat dibuat.
                                         -- Lihat Section 8 untuk kenapa ini perlu.

    -- Penjadwalan
    assigned_date       DATE NOT NULL,

    -- Status & Asal
    status              task_status NOT NULL DEFAULT 'PENDING',
    source              task_source NOT NULL DEFAULT 'MANUAL',

    -- Flag AI
    is_ambiguous        BOOLEAN NOT NULL DEFAULT FALSE,
    ai_generated        BOOLEAN NOT NULL DEFAULT FALSE,

    -- Alur Tindak-lanjut Miss
    missed_follow_up    missed_follow_up NOT NULL DEFAULT 'NONE',

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Penjelasan Kolom Penting

| Kolom | Null? | Penjelasan Bisnis |
| :--- | :---: | :--- |
| `goal_id` | ✅ | Task tanpa goal = task lepas. Reflection Agent TIDAK akan membuat follow-up chip untuk task lepas. |
| `estimated_minutes` | ✅ | `NULL` = durasi belum diketahui → UI tampilkan `(?)` → user tap → input inline → `PATCH /clarify` |
| `recurrence_rule` | ✅ | Jika terisi, `weekly-recurrence-generator` akan membuat salinan task ini setiap minggu |
| `recurrence_group_id` | ✅ | Kunci pengelompokan instance recurring task. Dipakai generator untuk cari "instance terbaru" tanpa peduli statusnya — lihat Section 8 |
| `is_ambiguous` | ❌ | `TRUE` jika `estimated_minutes IS NULL` (di-set oleh `validate_ambiguity` node LangGraph) |
| `ai_generated` | ❌ | `TRUE` jika task berasal dari brain-dump pipeline; `FALSE` jika input manual user |
| `missed_follow_up` | ❌ | Mesin status untuk alur follow-up (lihat Section 9) |

### Index

```sql
-- Paling sering diquery: "task minggu ini milik user X"
CREATE INDEX tasks_user_date_idx ON tasks (user_id, assigned_date);

-- Untuk Reflection Agent: "task MISSED milik user X yang terhubung goal"
CREATE INDEX tasks_user_status_goal_idx ON tasks (user_id, status, goal_id)
    WHERE status = 'MISSED';

-- Untuk cron weekly-recurrence-generator: cari instance terbaru per grup recurring,
-- TANPA memandang status (MISSED tidak boleh mematikan rantai recurrence)
CREATE INDEX tasks_recurrence_group_idx ON tasks (recurrence_group_id, assigned_date DESC)
    WHERE recurrence_group_id IS NOT NULL;

-- Cegah generator membuat duplikat kalau job dijalankan ulang untuk minggu yang sama
CREATE UNIQUE INDEX tasks_recurrence_group_week_uidx
    ON tasks (recurrence_group_id, assigned_date)
    WHERE recurrence_group_id IS NOT NULL;

-- Untuk filter follow-up chip di UI
CREATE INDEX tasks_follow_up_pending_idx ON tasks (user_id, missed_follow_up)
    WHERE missed_follow_up = 'PENDING';

CREATE TRIGGER tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### Row Level Security (RLS)

```sql
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tasks: all own" ON tasks
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

> [!WARNING]
> Policy ini memberi client hak CRUD penuh ke barisnya sendiri lewat Supabase SDK langsung. Ini **jaring pengaman kedua**, bukan jalur tulis utama — satu-satunya jalur tulis yang sah adalah FastAPI (pakai `SUPABASE_SERVICE_ROLE_KEY`), yang menjaga aturan bisnis (state machine `missed_follow_up`, validasi `is_ambiguous`, dll). Mobile app tidak boleh memanggil tabel `tasks`/`goals`/`task_suggestions` langsung ke Supabase untuk operasi tulis.

---

## 6. Tabel: `task_suggestions`

Menyimpan saran reschedule dari Scheduler Agent secara terpisah agar histori saran terlacak dan tabel `tasks` tidak overcrowded dengan kolom nullable tambahan.

```sql
CREATE TYPE suggestion_status AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED');

CREATE TABLE task_suggestions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id           UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    suggested_date    DATE NOT NULL,      -- tanggal alternatif yang disarankan AI
    reason            TEXT,              -- alasan singkat dari AI, misal: "overload di Senin"
    status            suggestion_status NOT NULL DEFAULT 'PENDING',
    responded_at      TIMESTAMPTZ,       -- kapan user menjawab (ACCEPTED/REJECTED)
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Aturan Bisnis

- Hanya boleh ada **1 saran `PENDING`** per `task_id` dalam satu waktu. Saran lama secara otomatis diset `REJECTED` ketika saran baru dibuat untuk task yang sama.
- Saat user klik **Terima**: task.`assigned_date` diupdate → saran diset `ACCEPTED` → `responded_at` diisi.
- Saat user klik **Abaikan**: saran diset `REJECTED` → `responded_at` diisi → tidak ada yang berubah di `tasks`.

```sql
-- Constraint: max 1 saran PENDING per task
CREATE UNIQUE INDEX task_suggestions_one_pending_per_task
    ON task_suggestions (task_id)
    WHERE status = 'PENDING';

CREATE INDEX task_suggestions_user_pending_idx
    ON task_suggestions (user_id, status)
    WHERE status = 'PENDING';
```

### Row Level Security (RLS)

```sql
ALTER TABLE task_suggestions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "task_suggestions: all own" ON task_suggestions
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

---

## 7. Tabel: `ai_insights`

Hasil analisis mingguan dari Reflection Agent. Berisi satu insight ringkas per siklus.

```sql
CREATE TABLE ai_insights (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content     TEXT NOT NULL,           -- teks insight dari AI, maks ~280 karakter
    week_of     DATE NOT NULL,           -- tanggal Senin dari minggu yang dianalisis
    surfaced    BOOLEAN NOT NULL DEFAULT TRUE,  -- TRUE = layak tampil di UI
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Aturan Bisnis

- `weekly-reflection` cron job **hanya** menulis ke tabel ini jika ada `≥ 2 task MISSED` dalam satu `goal` di minggu tersebut. Jika kondisi tidak terpenuhi, tidak ada baris baru ditulis.
- `surfaced = FALSE` digunakan untuk menyembunyikan insight yang sudah usang atau sudah dilihat (opsional untuk masa depan).

```sql
CREATE INDEX ai_insights_user_surfaced_idx ON ai_insights (user_id, week_of DESC)
    WHERE surfaced = TRUE;
```

### Row Level Security (RLS)

```sql
ALTER TABLE ai_insights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_insights: read own" ON ai_insights
    FOR SELECT USING (auth.uid() = user_id);
```

---

## 8. Format `recurrence_rule`

`tasks.recurrence_rule` menggunakan format **string kustom sederhana** yang mudah diparsing oleh AI (Extractor Agent) maupun kode generator cron.

| Nilai | Makna | Contoh Task yang Cocok |
| :--- | :--- | :--- |
| `'daily'` | Setiap hari (termasuk weekend) | Minum vitamin |
| `'weekdays'` | Senin–Jumat saja | Morning standup |
| `'weekends'` | Sabtu & Minggu saja | Olahraga pagi |
| `'2x/week'` | 2 kali seminggu (AI yang tentukan hari) | Gym |
| `'3x/week'` | 3 kali seminggu | Latihan lari |
| `'weekly'` | 1 kali seminggu (hari yang sama) | Review mingguan |

> [!NOTE]
> `weekly-recurrence-generator` (cron Minggu malam) mengambil **instance terbaru per `recurrence_group_id`** (bukan per `user_id + recurrence_rule` mentah) — diurutkan `assigned_date DESC`, **tanpa filter status**. Ini penting: task recurring yang `MISSED` minggu lalu tetap harus jadi acuan untuk generate instance minggu depan. Kalau filter status ikut disertakan (seperti draf sebelumnya), satu kali skip akan menghentikan recurrence itu selamanya — bertentangan dengan prinsip *Never Miss Twice* ALUR.
>
> Saat sebuah task baru dibuat dengan `recurrence_rule` terisi (baik manual maupun dari brain-dump) dan `recurrence_group_id` masih kosong, backend WAJIB mengisi `recurrence_group_id = id` task itu sendiri — ini menjadikannya "origin" dari grup. Semua instance mingguan berikutnya mewarisi `recurrence_group_id` yang sama, bukan membuat grup baru.

---

## 9. State Machine: `missed_follow_up`

Mesin status untuk alur tindak-lanjut task yang terlewat. Hanya task yang **terhubung goal** (`goal_id IS NOT NULL`) atau **berulang** (`recurrence_rule IS NOT NULL`) yang masuk ke alur ini.

```
                         ┌──────────────────────────────────────────────────────┐
                         │ Nightly cron (00:00 timezone)                         │
                         │ PENDING task lewat hari → status = 'MISSED'           │
                         │ Reflection Agent (ringan) cek:                        │
                         │   goal_id IS NOT NULL OR recurrence_rule IS NOT NULL? │
                         └──────────┬───────────────────────────────────────────┘
                                    │
                        ┌───────────▼──────────┐
                        │  missed_follow_up     │
             ┌──────────│  = 'NONE' (default)   │
             │ Ya       └───────────┬───────────┘
             │                     │ Tidak (task lepas)
             ▼                     ▼
  missed_follow_up           Tetap 'NONE' selamanya
  = 'PENDING'                (hanya tercatat sebagai histori MISSED)
      │
      │  (chip muncul di UI besok pagi)
      │
      ├─── [Udah, lupa centang] ──► task.status = 'DONE'  |  missed_follow_up = 'FORGOT'
      │
      ├─── [Emang skip]         ──► task.status = 'MISSED' |  missed_follow_up = 'SKIPPED'
      │
      └─── [Pindah ke hari ini] ──► task.assigned_date = today
                                    task.status = 'PENDING'
                                    missed_follow_up = 'RESCHEDULED'
```

---

## 10. Cron Jobs (`pg_cron`)

Semua job harus diuji via `GET /debug/run-cron/{job_name}` **sebelum** didaftarkan ke `pg_cron`.

```sql
-- 1. Nightly Status Check: tandai task lewat hari menjadi MISSED
-- PENTING: harus timezone-aware per user, bukan CURRENT_DATE server (default UTC).
-- users.timezone ada justru untuk ini — jalan tiap jam, bukan sekali di jam tetap,
-- supaya midnight tiap user ke-cover dalam toleransi maks 1 jam.
SELECT cron.schedule(
    'nightly-status-check',
    '0 * * * *',  -- tiap jam, menit ke-0
    $$
        UPDATE tasks t
        SET status = 'MISSED', updated_at = NOW()
        FROM users u
        WHERE t.user_id = u.id
          AND t.status = 'PENDING'
          AND t.assigned_date < (NOW() AT TIME ZONE u.timezone)::date;
        -- Catatan: Reflection Agent (ringan) di-invoke dari FastAPI Edge Function
        -- setelah UPDATE ini, via pg_cron → Edge Function URL
    $$
);

-- 2. Weekly Recurrence Generator: buat task minggu depan dari recurrence_rule aktif
SELECT cron.schedule(
    'weekly-recurrence-generator',
    '0 15 * * 0',  -- 15:00 UTC Minggu = 22:00 WIB Minggu
    $$
        -- Logic dijalankan via FastAPI Edge Function (bukan SQL murni)
        -- karena butuh parsing recurrence_rule string
        SELECT net.http_post(
            url := current_setting('app.backend_url') || '/internal/cron/recurrence',
            headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.cron_secret'))
        );
    $$
);

-- 3. Weekly Reflection: tulis ai_insights jika ada goal dengan ≥2 task MISSED
SELECT cron.schedule(
    'weekly-reflection',
    '30 15 * * 0',  -- 30 menit setelah recurrence generator
    $$
        SELECT net.http_post(
            url := current_setting('app.backend_url') || '/internal/cron/reflection',
            headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.cron_secret'))
        );
    $$
);
```

> [!NOTE]
> Job `nightly-status-check` cukup jalankan UPDATE SQL langsung (timezone-aware, lihat di atas). Jobs kompleks (`recurrence` dan `reflection`) memanggil FastAPI internal endpoint karena membutuhkan logika Python/LangGraph. Gunakan `pg_net` extension di Supabase untuk `http_post`.
>
> **Known limitation (diterima untuk MVP)**: `weekly-recurrence-generator` dan `weekly-reflection` masih jalan di jam UTC tetap (bukan per-timezone user). Untuk cadence mingguan, pergeseran beberapa jam antar-timezone dianggap dapat ditoleransi — beda dengan `nightly-status-check` yang harus akurat karena langsung memengaruhi status harian yang dilihat user. Kalau nanti terbukti masalah (user di zona waktu jauh dari WIB komplain), pindahkan ke pola per-user-timezone yang sama seperti job nightly.

---

## 11. Migrasi: Urutan Eksekusi

Jalankan file migrasi di Supabase SQL Editor atau via `supabase db push` dalam urutan berikut:

```
001_create_enum_types.sql          -- Semua CREATE TYPE
002_create_trigger_updated_at.sql  -- Fungsi reusable updated_at trigger
003_create_users.sql               -- Tabel users + auth trigger
004_create_goals.sql               -- Tabel goals + RLS
005_create_tasks.sql               -- Tabel tasks + RLS + index
006_create_task_suggestions.sql    -- Tabel task_suggestions + RLS (Fase 3, bisa skip Fase 1)
007_create_ai_insights.sql         -- Tabel ai_insights + RLS (Fase 3, bisa skip Fase 1)
008_setup_rls_policies.sql         -- Verifikasi semua RLS aktif
009_setup_pg_cron.sql              -- Daftarkan cron jobs (HANYA setelah Fase 3 siap)
```

> [!WARNING]
> **Strategi Fase 1**: yang perlu disiapkan lebih awal cuma **kolom-kolom AI di tabel `tasks`** (`is_ambiguous`, `ai_generated`, `missed_follow_up`, `recurrence_group_id`, dst — sudah tercakup di `005_create_tasks.sql`), karena menambah kolom lewat `ALTER TABLE` pada tabel yang sudah berisi data produksi itu berisiko. Ini **tidak berlaku** untuk `task_suggestions` dan `ai_insights` — keduanya tabel independen baru, tanpa data existing yang perlu dimigrasikan, jadi membuatnya tetap aman dilakukan belakangan di Fase 3 sesuai tabel Section 1. Jangan buat lebih awal dari yang diperlukan hanya karena alasan "menghindari migrasi nanti" — alasan itu tidak berlaku untuk tabel baru.

---

## 12. Checklist RLS (Verifikasi)

Jalankan query ini untuk memastikan RLS aktif di semua tabel sebelum go-live:

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
-- Semua tabel harus menampilkan rowsecurity = TRUE
```

---

## 13. Environment Variables yang Diperlukan

Lihat [`ENV_GUIDE.md`](./_docs/ENV_GUIDE.md) untuk panduan lengkap. Variabel khusus database:

| Variabel | Siapa yang Butuh | Keterangan |
| :--- | :--- | :--- |
| `PUBLIC_SUPABASE_URL` | Mobile, Web, Backend | URL publik project Supabase |
| `PUBLIC_SUPABASE_ANON_KEY` | Mobile, Web | Kunci anonim, boleh di-bundle ke client |
| `SUPABASE_SERVICE_ROLE_KEY` | Backend **saja** | Bypass RLS — JANGAN pernah ke client |
| `DATABASE_URL` | Backend (opsional) | Untuk koneksi langsung via psycopg2/SQLAlchemy |