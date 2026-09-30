-- 016_add_ai_profile_summary.sql
-- Add ai_profile_summary column to users table for Hierarchical Memory / Core Profile

ALTER TABLE users ADD COLUMN IF NOT EXISTS ai_profile_summary JSONB DEFAULT '{}';
