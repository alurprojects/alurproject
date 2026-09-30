-- 013_create_embeddings.sql
-- Table embeddings, vector index, RLS policies, and match_embeddings RPC

CREATE TYPE embedding_source AS ENUM ('TASK', 'CONVERSATION', 'INSIGHT');

CREATE TABLE embeddings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_type     embedding_source NOT NULL,
    source_id       UUID NOT NULL,           -- FK ke tasks.id / conversation_logs.id / ai_insights.id
    content_text    TEXT NOT NULL,            -- teks asli yang di-embed
    embedding       vector(768) NOT NULL,    -- dimensi 768 (Gemini text-embedding-004)
    metadata        JSONB DEFAULT '{}',      -- konteks tambahan (assigned_date, message_type, dll)
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index untuk similarity search (cosine distance)
CREATE INDEX embeddings_user_vector_idx
    ON embeddings USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

CREATE INDEX embeddings_user_source_idx
    ON embeddings (user_id, source_type);

-- Prevent duplicate embeddings per source
CREATE UNIQUE INDEX embeddings_source_uidx
    ON embeddings (source_type, source_id);

-- Row Level Security (RLS)
ALTER TABLE embeddings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "embeddings: all own" ON embeddings
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Supabase RPC function for vector similarity search
CREATE OR REPLACE FUNCTION match_embeddings(
    query_embedding vector(768),
    match_user_id UUID,
    match_count INT DEFAULT 10,
    filter_source embedding_source DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    source_type embedding_source,
    source_id UUID,
    content_text TEXT,
    metadata JSONB,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id,
        e.source_type,
        e.source_id,
        e.content_text,
        e.metadata,
        1 - (e.embedding <=> query_embedding) AS similarity
    FROM embeddings e
    WHERE e.user_id = match_user_id
      AND (filter_source IS NULL OR e.source_type = filter_source)
    ORDER BY e.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
