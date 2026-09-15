-- 001_create_enum_types.sql
-- Enum types for goals, tasks, and suggestions

CREATE TYPE goal_status AS ENUM ('ACTIVE', 'DONE', 'ARCHIVED');
CREATE TYPE task_status AS ENUM ('PENDING', 'DONE', 'MISSED');
CREATE TYPE task_source AS ENUM ('MANUAL', 'BRAIN_DUMP');
CREATE TYPE missed_follow_up AS ENUM ('NONE', 'PENDING', 'FORGOT', 'SKIPPED', 'RESCHEDULED');
CREATE TYPE suggestion_status AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED');
