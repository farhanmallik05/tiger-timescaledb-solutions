-- ============================================================================
-- Tiger Cloud / TimescaleDB Challenge 5: AI Vector Search with pgvector
-- Challenge ID: 01a11b66-3a25-902e-3690-f9ea40cd5014
-- Description: Store and query high-dimensional vector embeddings in PostgreSQL
-- ============================================================================

-- 1. Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- 2. Create Incident Knowledgebase Table with 384-dimensional dense vectors
DROP TABLE IF EXISTS incident_embeddings CASCADE;

CREATE TABLE incident_embeddings (
    id              BIGSERIAL PRIMARY KEY,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    incident_id     VARCHAR(32) NOT NULL,
    service_name    VARCHAR(64) NOT NULL,
    severity        VARCHAR(16) NOT NULL,
    title           TEXT NOT NULL,
    root_cause      TEXT NOT NULL,
    resolution      TEXT NOT NULL,
    embedding       vector(384) NOT NULL
);

-- 3. HNSW (Hierarchical Navigable Small World) Index for Sub-Millisecond Cosine Search
CREATE INDEX IF NOT EXISTS idx_incident_embedding_hnsw
    ON incident_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- 4. B-Tree Indexes for Hybrid Filtering
CREATE INDEX IF NOT EXISTS idx_incident_service_time
    ON incident_embeddings (service_name, created_at DESC);

-- ============================================================================
-- Hybrid AI Retrieval-Augmented Generation (RAG) Queries
-- ============================================================================

-- Semantic Search with Metadata & Time-Window Filtering
-- Finds top 5 most semantically similar historical outages within the last 90 days
-- using the cosine distance operator (<=>)
SELECT
    incident_id,
    service_name,
    severity,
    title,
    root_cause,
    resolution,
    1 - (embedding <=> '[0.042, -0.015, ...]'::vector) AS cosine_similarity,
    embedding <=> '[0.042, -0.015, ...]'::vector       AS cosine_distance
FROM incident_embeddings
WHERE created_at >= NOW() - INTERVAL '90 days'
  AND severity IN ('CRITICAL', 'HIGH')
ORDER BY embedding <=> '[0.042, -0.015, ...]'::vector
LIMIT 5;
