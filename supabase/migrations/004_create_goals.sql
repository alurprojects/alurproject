-- 004_create_goals.sql
-- Table goals, indexes, updated_at trigger, and RLS policies

CREATE TABLE goals (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title        TEXT NOT NULL,
    description  TEXT,
    deadline     DATE,
    status       goal_status NOT NULL DEFAULT 'ACTIVE',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index & Trigger
CREATE INDEX goals_user_id_idx ON goals (user_id);
CREATE INDEX goals_status_idx ON goals (user_id, status);

CREATE TRIGGER goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Row Level Security (RLS)
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "goals: all own" ON goals
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
