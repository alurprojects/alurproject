# DATABASE.md — ALUR: Schema End-to-End

**Platform**: Supabase (PostgreSQL 15+) dengan Row Level Security (RLS), `pg_cron`, dan Supabase Auth.

> [!IMPORTANT]
> Dokumen ini adalah **Single Source of Truth** untuk skema database ALUR. Setiap perubahan schema harus diperbarui di sini terlebih dahulu sebelum dieksekusi sebagai migrasi.

---

## 1. Ringkasan Tabel

| Tabel | Fase | Deskripsi |
| :--- | :---: | :--- |
| `users` | 1 | Profil, timezone, dan kapasitas harian user |
| `goals` | 1 | Target / tujuan jangka menengah-panjang user (ditampilkan di tab Profile) |
| `tasks` | 1 | Unit kerja utama; bisa manual, brain-dump, atau dari Chat Room |
| `conversation_logs` | 2 | **BARU** — Seluruh interaksi Chat Room (user & AI), bahan evaluasi Reflection Agent |
| `task_suggestions` | 3 | Saran reschedule dari Scheduler Agent |
| `ai_insights` | 2-3 | Insight dari Reflection Agent + Companion Agent (capacity warning, pola, refleksi) |
| `google_calendar_connections` | **Tahap B** | Koneksi OAuth Google Calendar per user (read-only) |

---

## 2. Diagram Relasi (ERD)

```
users (1)
 ├──────────────────────────────────────────── goals (N)
 │                                               │
 ├──────────────────────────────────────────── tasks (N) ─── goal_id → goals (nullable)
 │                                                │
 │                                                └──────── task_suggestions (N)
 │
 ├──────────────────────────────────────────── conversation_logs (N)  ← BARU
 │                                                │
 │                                                └──────── extracted_task_ids → tasks (nullable, array)
 │
 ├──────────────────────────────────────────── ai_insights (N)
 └──────────────────────────────────────────── google_calendar_connections (N, Tahap B)
```

---

## 3. Tabel: `users`

Diteruskan dari Supabase Auth. Baris dibuat otomatis oleh trigger saat user pertama kali login.

```sql
CREATE TABLE users (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email       TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL DEFAULT '',
    timezone    TEXT NOT NULL DEFAULT 'Asia/Jakarta',
    daily_capacity_hours  NUMERIC(3,1) NOT NULL DEFAULT 8.0,
    preferences JSONB NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Kolom `preferences` (JSONB)

```jsonc
{
  "theme": "dark",                  // "dark" | "light" | "system" (default: "system")
  "language": "id",                 // "id" | "en" (default: "id")
  "week_start": "monday",           // "monday" | "sunday" (default: "monday")
  "todo_default_view": "daily",     // "daily" | "weekly" (default: "daily")
  "notifications": {
    "enabled": true,
    "reminder_hour": 8
  }
}
```

### Index & Trigger

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

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
    description  TEXT,
    deadline     DATE,
    status       goal_status NOT NULL DEFAULT 'ACTIVE',
    priority     SMALLINT CHECK (priority IS NULL OR priority >= 1),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX goals_user_id_idx ON goals (user_id);
CREATE INDEX goals_status_idx ON goals (user_id, status);

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

Tabel inti. Menangani task manual, brain-dump, Chat Room extraction, recurrence, dan alur miss → follow-up.

```sql
CREATE TYPE task_status        AS ENUM ('PENDING', 'DONE', 'MISSED');
CREATE TYPE task_source        AS ENUM ('MANUAL', 'BRAIN_DUMP', 'CHAT_ROOM');
CREATE TYPE missed_follow_up   AS ENUM ('NONE', 'PENDING', 'FORGOT', 'SKIPPED', 'RESCHEDULED');

CREATE TABLE tasks (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal_id             UUID REFERENCES goals(id) ON DELETE SET NULL,

    title               TEXT NOT NULL,
    estimated_minutes   INT CHECK (estimated_minutes IS NULL OR estimated_minutes > 0),
    recurrence_rule     TEXT,
    recurrence_group_id UUID,

    assigned_date       DATE NOT NULL,

    status              task_status NOT NULL DEFAULT 'PENDING',
    source              task_source NOT NULL DEFAULT 'MANUAL',

    is_ambiguous        BOOLEAN NOT NULL DEFAULT FALSE,
    ai_generated        BOOLEAN NOT NULL DEFAULT FALSE,

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
| `recurrence_group_id` | ✅ | Kunci pengelompokan instance recurring task |
| `source` | ❌ | `MANUAL`, `BRAIN_DUMP`, atau `CHAT_ROOM` — membedakan asal task |
| `is_ambiguous` | ❌ | `TRUE` jika `estimated_minutes IS NULL` |
| `ai_generated` | ❌ | `TRUE` jika task berasal dari pipeline AI |
| `missed_follow_up` | ❌ | Mesin status untuk alur follow-up (lihat Section 9) |

### Index

```sql
CREATE INDEX tasks_user_date_idx ON tasks (user_id, assigned_date);

CREATE INDEX tasks_user_status_goal_idx ON tasks (user_id, status, goal_id)
    WHERE status = 'MISSED';

CREATE INDEX tasks_recurrence_group_idx ON tasks (recurrence_group_id, assigned_date DESC)
    WHERE recurrence_group_id IS NOT NULL;

CREATE UNIQUE INDEX tasks_recurrence_group_week_uidx
    ON tasks (recurrence_group_id, assigned_date)
    WHERE recurrence_group_id IS NOT NULL;

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

---

## 6. Tabel: `conversation_logs` (**BARU — Fase 2**)

Menyimpan seluruh interaksi Chat Room antara user dan AI. Berfungsi sebagai:
- **Bahan evaluasi** bagi Reflection Agent (pola kendala, mood, kapasitas)
- **Konteks percakapan** bagi Companion Agent (memory window)
- **Sumber data** bagi analisis metrik AI (insight generation)

```sql
CREATE TYPE chat_role         AS ENUM ('USER', 'AI');
CREATE TYPE chat_message_type AS ENUM ('TASK_CAPTURE', 'REFLECTION', 'CHAT', 'CAPACITY_QUERY');

CREATE TABLE conversation_logs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    role                chat_role NOT NULL,
    content             TEXT NOT NULL,
    message_type        chat_message_type NOT NULL DEFAULT 'CHAT',

    -- Jika pesan ini menghasilkan task (role = AI, message_type = TASK_CAPTURE)
    extracted_task_ids  UUID[] DEFAULT '{}',

    -- Metadata AI (hanya diisi untuk role = AI)
    tone_used           TEXT,           -- 'HONEST' | 'GENTLE'
    mood_detected       TEXT,           -- sinyal overload/burnout yang terdeteksi (bukan mood umum)

    session_date        DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Kolom tambahan untuk mekanisme retensi data
ALTER TABLE conversation_logs
  ADD COLUMN pending_deletion_notified_at TIMESTAMPTZ,
  ADD COLUMN retention_override BOOLEAN NOT NULL DEFAULT FALSE;
```

### Penjelasan Kolom

| Kolom | Penjelasan |
| :--- | :--- |
| `role` | `USER` = pesan dari user, `AI` = respons dari Companion Agent |
| `message_type` | Klasifikasi otomatis oleh Companion Agent. `TASK_CAPTURE` = user bermaksud menambah task. `REFLECTION` = user bercerita/curhat tentang kendala. `CHAT` = percakapan umum. `CAPACITY_QUERY` = user bertanya soal kapasitas. |
| `extracted_task_ids` | Array UUID task yang berhasil diekstrak dari pesan ini (kosong jika bukan TASK_CAPTURE) |
| `tone_used` | Nada AI: `HONEST` (default, lugas) atau `GENTLE` (saat mendeteksi burnout/overload) |
| `mood_detected` | Sinyal overload/burnout yang terdeteksi dari pesan sebelumnya — bukan mood umum (senang/sedih/dll) |
| `session_date` | Tanggal sesi chat (untuk query "chat hari ini") |
| `pending_deletion_notified_at` | Timestamp saat log ini ditandai mendekati batas retensi (83 hari). `NULL` = belum ditandai. |
| `retention_override` | `TRUE` = log dikecualikan dari auto-hapus selamanya (user pilih "Simpan Selamanya"). Default `FALSE`. |

### Index

```sql
-- Query utama: "chat hari ini milik user X"
CREATE INDEX conversation_logs_user_session_idx
    ON conversation_logs (user_id, session_date DESC, created_at);

-- Untuk Reflection Agent: ambil semua refleksi user dalam 7 hari terakhir
CREATE INDEX conversation_logs_user_type_idx
    ON conversation_logs (user_id, message_type, session_date DESC)
    WHERE message_type IN ('REFLECTION', 'CAPACITY_QUERY');

-- Untuk Companion Agent context window: 20 pesan terakhir
CREATE INDEX conversation_logs_user_recent_idx
    ON conversation_logs (user_id, created_at DESC);
```

### Row Level Security (RLS)

```sql
ALTER TABLE conversation_logs ENABLE ROW LEVEL SECURITY;

-- User hanya bisa baca chat dirinya sendiri
CREATE POLICY "conversation_logs: read own" ON conversation_logs
    FOR SELECT USING (auth.uid() = user_id);

-- Insert dilakukan via backend (service_role_key), bukan langsung dari client
-- Tapi kita tetap buat policy INSERT untuk safety
CREATE POLICY "conversation_logs: insert own" ON conversation_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

> [!WARNING]
> `conversation_logs` berisi data sensitif (curhat user). Tidak boleh diekspos ke endpoint publik selain yang memiliki auth. Backend bertanggung jawab untuk filtering dan sanitasi sebelum mengirim ke LLM.

---

## 7. Tabel: `task_suggestions`

Menyimpan saran reschedule dari Scheduler Agent.

```sql
CREATE TYPE suggestion_status AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED');

CREATE TABLE task_suggestions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id           UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    suggested_date    DATE NOT NULL,
    reason            TEXT,
    status            suggestion_status NOT NULL DEFAULT 'PENDING',
    responded_at      TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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

## 8. Tabel: `ai_insights`

Hasil analisis dari Reflection Agent. Diperluas dengan `insight_type` untuk membedakan sumber insight.

```sql
CREATE TYPE insight_type AS ENUM (
    'WEEKLY_REFLECTION',    -- analisis pola mingguan dari tasks + conversation_logs
    'CAPACITY_WARNING',     -- peringatan kapasitas berlebih
    'PATTERN_DETECTION'     -- deteksi pola berulang (misal: selalu skip di hari Jumat)
);

CREATE TABLE ai_insights (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content      TEXT NOT NULL,
    insight_type insight_type NOT NULL DEFAULT 'WEEKLY_REFLECTION',
    week_of      DATE NOT NULL,
    surfaced     BOOLEAN NOT NULL DEFAULT TRUE,
    source_data  JSONB DEFAULT '{}',   -- metadata: task_ids analyzed, chat_sessions referenced
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ai_insights_user_surfaced_idx ON ai_insights (user_id, week_of DESC)
    WHERE surfaced = TRUE;
```

### Aturan Bisnis

- `WEEKLY_REFLECTION`: ditulis oleh cron `weekly-reflection`, berdasarkan **combined data** (tasks + conversation_logs).
- `CAPACITY_WARNING`: ditulis secara real-time oleh Companion Agent saat mendeteksi overload.
- `PATTERN_DETECTION`: ditulis oleh Reflection Agent saat menemukan pola berulang lintas minggu.
- `source_data` menyimpan referensi ke data yang digunakan untuk generate insight (untuk debugging/transparency).

### Row Level Security (RLS)

```sql
ALTER TABLE ai_insights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_insights: read own" ON ai_insights
    FOR SELECT USING (auth.uid() = user_id);
```

---

## 8.5 Tabel: `google_calendar_connections` *(Tahap B — bukan Fase 1)*

> [!NOTE]
> Tabel ini aman dibuat belakangan saat Google Calendar Tahap B siap dibangun.

```sql
CREATE TABLE google_calendar_connections (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    access_token      TEXT NOT NULL,
    refresh_token     TEXT NOT NULL,
    token_expiry      TIMESTAMPTZ NOT NULL,
    gcal_calendar_id  TEXT NOT NULL,
    sync_enabled      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX gcal_connections_user_calendar_uidx
    ON google_calendar_connections (user_id, gcal_calendar_id);

CREATE TRIGGER gcal_connections_updated_at
    BEFORE UPDATE ON google_calendar_connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### Row Level Security (RLS)

```sql
ALTER TABLE google_calendar_connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "gcal_connections: all own" ON google_calendar_connections
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

---

## 9. Format `recurrence_rule`

| Nilai | Makna | Contoh Task |
| :--- | :--- | :--- |
| `'daily'` | Setiap hari | Minum vitamin |
| `'weekdays'` | Senin–Jumat | Morning standup |
| `'weekends'` | Sabtu & Minggu | Olahraga pagi |
| `'2x/week'` | 2 kali seminggu | Gym |
| `'3x/week'` | 3 kali seminggu | Latihan lari |
| `'weekly'` | 1 kali seminggu | Review mingguan |

> [!NOTE]
> `weekly-recurrence-generator` mengambil instance terbaru per `recurrence_group_id` — tanpa filter status. Task `MISSED` tetap jadi acuan generate minggu depan.

---

## 10. State Machine: `missed_follow_up`

```
Nightly cron (00:00 timezone)
  PENDING task lewat hari → status = 'MISSED'
  Reflection Agent cek: goal_id IS NOT NULL OR recurrence_rule IS NOT NULL?
    │
    ├─ Ya → missed_follow_up = 'PENDING' (chip muncul besok pagi)
    │         │
    │         ├── [Udah, lupa centang] → status = DONE, follow_up = FORGOT
    │         ├── [Emang skip]        → status = MISSED, follow_up = SKIPPED
    │         └── [Pindah hari ini]   → date = today, status = PENDING, follow_up = RESCHEDULED
    │
    └─ Tidak → Tetap NONE (hanya tercatat sebagai histori)
```

---

## 11. Cron Jobs (`pg_cron`)

```sql
-- 1. Nightly Status Check (tiap jam, timezone-aware per user)
SELECT cron.schedule(
    'nightly-status-check',
    '0 * * * *',
    $$
        UPDATE tasks t
        SET status = 'MISSED', updated_at = NOW()
        FROM users u
        WHERE t.user_id = u.id
          AND t.status = 'PENDING'
          AND t.assigned_date < (NOW() AT TIME ZONE u.timezone)::date;
    $$
);

-- 2. Weekly Recurrence Generator (Minggu 22:00 WIB = 15:00 UTC)
SELECT cron.schedule(
    'weekly-recurrence-generator',
    '0 15 * * 0',
    $$
        SELECT net.http_post(
            url := current_setting('app.backend_url') || '/internal/cron/recurrence',
            headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.cron_secret'))
        );
    $$
);

-- 3. Weekly Reflection — ENHANCED: sekarang juga proses conversation_logs
SELECT cron.schedule(
    'weekly-reflection',
    '30 15 * * 0',
    $$
        SELECT net.http_post(
            url := current_setting('app.backend_url') || '/internal/cron/reflection',
            headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.cron_secret'))
        );
    $$
);

-- 4a. Tandai log chat yang mendekati batas retensi (83 hari,
--     beri jeda 7 hari sebelum dihapus permanen di 90 hari)
SELECT cron.schedule(
    'conversation-log-notify-pending',
    '0 4 * * *',
    $$
        UPDATE conversation_logs
        SET pending_deletion_notified_at = NOW()
        WHERE created_at < NOW() - INTERVAL '83 days'
          AND pending_deletion_notified_at IS NULL
          AND retention_override = FALSE;
    $$
);

-- 4b. Hapus permanen log yang sudah diberi notice >= 7 hari
--     DAN tidak di-override user
SELECT cron.schedule(
    'conversation-log-hard-delete',
    '0 5 * * *',
    $$
        DELETE FROM conversation_logs
        WHERE pending_deletion_notified_at < NOW() - INTERVAL '7 days'
          AND retention_override = FALSE;
    $$
);
```

> [!NOTE]
> `weekly-reflection` sekarang memproses **combined data**: tasks (status, missed_follow_up) + conversation_logs (refleksi, mood, kendala) untuk menghasilkan insight yang lebih kaya.

---

## 12. Migrasi: Urutan Eksekusi

```
001_create_enum_types.sql               -- Semua CREATE TYPE (termasuk chat_role, chat_message_type, insight_type)
002_create_trigger_updated_at.sql       -- Fungsi reusable updated_at trigger
003_create_users.sql                    -- Tabel users + auth trigger
004_create_goals.sql                    -- Tabel goals + RLS
005_create_tasks.sql                    -- Tabel tasks + RLS + index (source enum sudah termasuk CHAT_ROOM)
006_create_conversation_logs.sql        -- BARU: Tabel conversation_logs + RLS (Fase 2, tapi buat awal)
007_create_task_suggestions.sql         -- Tabel task_suggestions + RLS (Fase 3)
008_create_ai_insights.sql              -- Tabel ai_insights + RLS (Fase 2-3, insight_type enum)
009_create_gcal_connections.sql         -- Tahap B
010_setup_rls_policies.sql              -- Verifikasi semua RLS aktif
011_setup_pg_cron.sql                   -- Daftarkan cron jobs (setelah Fase 3)
```

> [!WARNING]
> **Strategi migrasi**: `conversation_logs` sebaiknya dibuat di Fase 1 bersamaan dengan tabel lain (meski belum dipakai sampai Fase 2) — karena tabel ini independen dan tidak berisiko.

---

## 13. Checklist RLS (Verifikasi)

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
-- Semua tabel harus menampilkan rowsecurity = TRUE
```

---

## 14. Environment Variables

Lihat `ENV_GUIDE.md` untuk panduan lengkap. Variabel khusus database:

| Variabel | Siapa yang Butuh | Keterangan |
| :--- | :--- | :--- |
| `PUBLIC_SUPABASE_URL` | Mobile, Web, Backend | URL publik Supabase |
| `PUBLIC_SUPABASE_ANON_KEY` | Mobile, Web | Kunci anonim |
| `SUPABASE_SERVICE_ROLE_KEY` | Backend **saja** | Bypass RLS |
| `DATABASE_URL` | Backend (opsional) | Koneksi langsung |
