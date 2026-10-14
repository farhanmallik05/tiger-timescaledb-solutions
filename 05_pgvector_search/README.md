# Challenge 5: Implement AI-Powered Vector Search with pgvector
**Challenge ID**: `01a11b66-3a25-902e-3690-f9ea40cd5014`  
**Track**: 🐯 Tiger Data / TimescaleDB  
**Status**: Completed & Verified  

---

## 📌 Overview
Building modern AI applications with Retrieval-Augmented Generation (RAG) often requires running a separate dedicated vector database sidecar (like Pinecone, Milvus, or Qdrant), which adds operational complexity, data synchronization overhead, and network latency.

Tiger Cloud natively supports **`pgvector`** and **`pgvectorscale`**, enabling engineering teams to store high-dimensional embeddings directly alongside their relational schemas and time-series hypertables in PostgreSQL.

This project implements an AI-powered Incident Knowledgebase and Triaging engine:
- Stores **384-dimensional dense vector embeddings** using the `vector(384)` data type.
- Builds an **HNSW (Hierarchical Navigable Small World)** index for sub-millisecond approximate nearest neighbor (ANN) lookups.
- Performs semantic similarity search using the cosine distance operator (`<=>`).
- Supports **Hybrid Search**: combines semantic vector proximity with time-window filtering (`created_at >= NOW() - INTERVAL '90 days'`) and relational metadata filters (`severity IN ('CRITICAL', 'HIGH')`).

---

## 🛠 Schema Architecture (`vector_schema.sql`)
```sql
CREATE EXTENSION IF NOT EXISTS vector;

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

-- Fast Approximate Nearest Neighbor Index
CREATE INDEX idx_incident_embedding_hnsw
    ON incident_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
```

---

## 🚀 Execution & Query Verification
```bash
python 05_pgvector_search/pgvector_search.py
```

### Verification Highlights
- **Semantic Vector Distance**: Query *"PostgreSQL database connections exhausted under heavy traffic spikes"* accurately ranked `INC-8491` as the top match, instantly surfacing the root cause and PgBouncer resolution.
- **Root Cause Matching**: Query *"Pod killed with out of memory error memory leak"* accurately retrieved `INC-8472` with the memory leak diagnosis and streaming generator fix.
- **Single Database Simplicity**: Vector similarity searches execute directly within PostgreSQL with ACID transactions and relational joins.
