-- 006_create_task_suggestions.sql
-- Table task_suggestions, unique partial index, and RLS policies

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

-- Indexes & Constraints
CREATE UNIQUE INDEX task_suggestions_one_pending_per_task
    ON task_suggestions (task_id)
    WHERE status = 'PENDING';

CREATE INDEX task_suggestions_user_pending_idx
    ON task_suggestions (user_id, status)
    WHERE status = 'PENDING';

-- Row Level Security (RLS)
ALTER TABLE task_suggestions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "task_suggestions: all own" ON task_suggestions
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
