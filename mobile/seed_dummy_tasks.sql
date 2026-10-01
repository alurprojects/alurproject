-- Seed dummy ALUR tasks — 1 minggu penuh, jalankan di Supabase SQL editor
-- User id default: 00000000-0000-0000-0000-000000000001
-- Ubah week_start sesuai Senin minggu ini

WITH w AS (SELECT date '2026-09-28'::date AS mon) -- SENIN 28 Sep 2026

INSERT INTO tasks (user_id, title, assigned_date, status, source, estimated_minutes, is_ambiguous, ai_generated, missed_follow_up)
SELECT '00000000-0000-0000-0000-000000000001', title, assigned_date, 'PENDING', 'MANUAL', mins, false, false, 'NONE'
FROM (SELECT * FROM (VALUES
  -- SENIN
  ('Morning jog',               (SELECT mon FROM w),       420),
  ('Team standup',              (SELECT mon FROM w),       540),
  ('Review PR #42',             (SELECT mon FROM w),       NULL),
  ('Wind down',                 (SELECT mon FROM w),      1320),
  -- SELASA
  ('Study Flutter',             (SELECT mon + 1 FROM w),   480),
  ('Lunch with Maya',           (SELECT mon + 1 FROM w),   720),
  ('Buy groceries',             (SELECT mon + 1 FROM w),   NULL),
  ('Pushups x50',               (SELECT mon + 1 FROM w),   NULL),
  -- RABU
  ('Deep work — ALUR spec',     (SELECT mon + 2 FROM w),   540),
  ('Call Mom',                  (SELECT mon + 2 FROM w),  1080),
  ('Make pasta',                (SELECT mon + 2 FROM w),   NULL),
  -- KAMIS
  ('Gym • Leg day',             (SELECT mon + 3 FROM w),   360),
  ('Client call',               (SELECT mon + 3 FROM w),   600),
  ('Write journal',             (SELECT mon + 3 FROM w),  1260),
  -- JUMAT (match screenshot)
  ('Daria''s 20th Birthday',     (SELECT mon + 4 FROM w),   NULL),
  ('Wake up',                   (SELECT mon + 4 FROM w),   540),
  ('Design Crit',               (SELECT mon + 4 FROM w),   600),
  ('Haircut with Vincent',      (SELECT mon + 4 FROM w),   780),
  ('Make pasta',                (SELECT mon + 4 FROM w),   NULL),
  ('Pushups x100',              (SELECT mon + 4 FROM w),   NULL),
  ('Wind down',                 (SELECT mon + 4 FROM w),  1260),
  -- SABTU
  ('Brunch',                    (SELECT mon + 5 FROM w),   600),
  ('Hiking',                    (SELECT mon + 5 FROM w),   480),
  ('Movie night',               (SELECT mon + 5 FROM w),  1200),
  -- MINGGU
  ('Weekly review',             (SELECT mon + 6 FROM w),   540),
  ('Plan next week',            (SELECT mon + 6 FROM w),   600),
  ('Family dinner',             (SELECT mon + 6 FROM w),  1080),
  ('Wind down',                 (SELECT mon + 6 FROM w),  1320)
) AS v(title, assigned_date, mins)) s;
