-- 007_create_ai_insights.sql
-- Table ai_insights, index, and RLS policies

CREATE TABLE ai_insights (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    week_of     DATE NOT NULL,
    surfaced    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX ai_insights_user_surfaced_idx ON ai_insights (user_id, week_of DESC)
    WHERE surfaced = TRUE;

-- Row Level Security (RLS)
ALTER TABLE ai_insights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_insights: read own" ON ai_insights
    FOR SELECT USING (auth.uid() = user_id);
