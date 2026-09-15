-- 003_create_users.sql
-- Table users, triggers (updated_at and auth.users sync), and RLS policies

CREATE TABLE users (
    id                    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email                 TEXT NOT NULL UNIQUE,
    name                  TEXT NOT NULL DEFAULT '',
    timezone              TEXT NOT NULL DEFAULT 'Asia/Jakarta',
    daily_capacity_hours  NUMERIC(3,1) NOT NULL DEFAULT 8.0,
    preferences           JSONB NOT NULL DEFAULT '{}',
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger: update updated_at otomatis
CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Trigger: buat baris users dari Supabase Auth saat signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users: read own" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users: update own" ON users
    FOR UPDATE USING (auth.uid() = id);
