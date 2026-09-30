-- 015_setup_morning_brief_cron.sql
-- Helper function and cron schedule for Morning Brief Generator

-- RPC function to find users eligible for morning brief
CREATE OR REPLACE FUNCTION users_due_morning_brief(current_utc_hour INT DEFAULT NULL)
RETURNS TABLE (
    id UUID,
    timezone TEXT,
    reminder_hour INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.timezone,
        COALESCE((u.preferences->'notifications'->>'reminder_hour')::INT, 8) AS reminder_hour
    FROM users u
    WHERE COALESCE((u.preferences->'notifications'->>'morning_brief_enabled')::BOOLEAN, TRUE) = TRUE;
END;
$$;

-- Schedule hourly cron for morning brief generation (if pg_cron is enabled)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        PERFORM cron.schedule(
            'morning-brief-generator',
            '0 * * * *',
            $cron$
                SELECT net.http_post(
                    url := COALESCE(current_setting('app.backend_url', true), 'http://backend:8000') || '/internal/cron/morning-brief',
                    headers := jsonb_build_object(
                        'Authorization', 'Bearer ' || COALESCE(current_setting('app.cron_secret', true), ''),
                        'X-Cron-Secret', COALESCE(current_setting('app.cron_secret', true), '')
                    )
                );
            $cron$
        );
    END IF;
END $$;
