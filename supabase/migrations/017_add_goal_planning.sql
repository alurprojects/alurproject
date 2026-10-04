-- 017_add_goal_planning.sql
-- Goal Breakdown (M14) + sinkron enum task_source dengan live DB.
-- Catatan: 008-011 tidak ada di repo (007 lompat ke 012). Jalankan
-- `supabase db diff --linked` sebelum apply untuk pastikan tidak ada drift.
-- Nilai enum baru TIDAK bisa dipakai dalam transaksi yang sama dengan
-- ALTER TYPE ... ADD VALUE, jadi file ini split: tambah value dulu (sudah
-- commit terpisah di live), baru ALTER TABLE di bawah. Jika live belum punya
-- CHAT_ROOM, hapus baris IF NOT EXISTS yang gagal dan jalankan manual.

-- 1. Enum task_source: sinkron CHAT_ROOM (sudah live, belum ada di 001) + GOAL_PLAN baru.
-- Postgres tidak support IF NOT EXISTS untuk ADD VALUE, jadi guard via DO block.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
        WHERE t.typname = 'task_source' AND e.enumlabel = 'CHAT_ROOM'
    ) THEN
        ALTER TYPE task_source ADD VALUE 'CHAT_ROOM';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
        WHERE t.typname = 'task_source' AND e.enumlabel = 'GOAL_PLAN'
    ) THEN
        ALTER TYPE task_source ADD VALUE 'GOAL_PLAN';
    END IF;
END $$;

-- 2. Enum plan_status untuk draft rencana goal (async GENERATING -> DRAFT -> ACCEPTED).
DO $$ BEGIN
    CREATE TYPE plan_status AS ENUM ('NONE', 'GENERATING', 'DRAFT', 'ACCEPTED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 3. Kolom goals untuk Goal Breakdown (M14).
ALTER TABLE goals ADD COLUMN IF NOT EXISTS target_hours_per_week NUMERIC;
ALTER TABLE goals ADD COLUMN IF NOT EXISTS definition_of_done TEXT;
ALTER TABLE goals ADD COLUMN IF NOT EXISTS plan JSONB NOT NULL DEFAULT '{}';
ALTER TABLE goals ADD COLUMN IF NOT EXISTS plan_draft JSONB NOT NULL DEFAULT '{}';
ALTER TABLE goals ADD COLUMN IF NOT EXISTS plan_status plan_status NOT NULL DEFAULT 'NONE';
ALTER TABLE goals ADD COLUMN IF NOT EXISTS last_replanned_at TIMESTAMPTZ;

-- 4. Kolom tasks: lindungi edit user dari replan mingguan.
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS user_modified BOOLEAN NOT NULL DEFAULT FALSE;

-- 5. Aturan bisnis (dokumentasi di DATABASE.md, bukan constraint keras):
-- replan hanya menyentuh ai_generated = TRUE AND status = 'PENDING'
-- AND assigned_date > CURRENT_DATE AND user_modified = FALSE.
-- Draft rencana TIDAK disimpan sebagai tasks agar nightly-status-check
-- tidak salah tandai jadi MISSED.
