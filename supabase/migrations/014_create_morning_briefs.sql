-- 014_create_morning_briefs.sql
-- Table morning_briefs, unique index per user per date, and RLS policies

CREATE TABLE morning_briefs (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    brief_date        DATE NOT NULL,
    content           JSONB NOT NULL,
    notification_sent BOOLEAN NOT NULL DEFAULT FALSE,
    opened_at         TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX morning_briefs_user_date_uidx
    ON morning_briefs (user_id, brief_date);

CREATE INDEX morning_briefs_unsent_idx
    ON morning_briefs (notification_sent, brief_date)
    WHERE notification_sent = FALSE;

-- Row Level Security (RLS)
ALTER TABLE morning_briefs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "morning_briefs: all own" ON morning_briefs
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
