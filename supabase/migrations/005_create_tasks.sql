-- 005_create_tasks.sql
-- Table tasks, AI & recurrence fields, indexes, trigger, and RLS policies

CREATE TABLE tasks (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal_id             UUID REFERENCES goals(id) ON DELETE SET NULL,

    -- Content
    title               TEXT NOT NULL,
    estimated_minutes   INT CHECK (estimated_minutes IS NULL OR estimated_minutes > 0),
    recurrence_rule     TEXT,
    recurrence_group_id UUID,

    -- Scheduling
    assigned_date       DATE NOT NULL,

    -- Status & Source
    status              task_status NOT NULL DEFAULT 'PENDING',
    source              task_source NOT NULL DEFAULT 'MANUAL',

    -- AI Flags
    is_ambiguous        BOOLEAN NOT NULL DEFAULT FALSE,
    ai_generated        BOOLEAN NOT NULL DEFAULT FALSE,

    -- Missed Follow-up
    missed_follow_up    missed_follow_up NOT NULL DEFAULT 'NONE',

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
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

-- Row Level Security (RLS)
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tasks: all own" ON tasks
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
