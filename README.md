# Tiger Cloud / TimescaleDB Production Suite 🐯⚡
> Complete solutions for the **Tiger Data / TimescaleDB Track** at **Global Hack Week: Hacktoberfest 2026** (Major League Hacking).

![Tiger Data](https://img.shields.io/badge/Tiger%20Data-TimescaleDB-orange?style=for-the-badge&logo=postgresql)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16+-blue?style=for-the-badge&logo=postgresql)
![pgvector](https://img.shields.io/badge/pgvector-HNSW%20Search-purple?style=for-the-badge)
![Status](https://img.shields.io/badge/Challenges-5%20of%205%20Verified-brightgreen?style=for-the-badge)
![Hacktoberfest](https://img.shields.io/badge/Hacktoberfest-2026-ff69b4?style=for-the-badge)

---

## 🎯 Track Overview & Challenge Index

This repository provides production-ready SQL schemas, ingestion pipelines, continuous aggregates, and AI vector search workflows for all 5 open challenges in the Tiger Data track:

| Challenge | Challenge ID | Focus Area | Verification Status |
| :--- | :--- | :--- | :--- |
| **1. First Hypertable Setup** | `01a11b54-794b-ea57-035a-4e2b701feb8d` | Time partitioning, 1-day chunks, compression policies | **Passed ✓** |
| **2. Continuous Aggregates (CAGGs)** | `01a11b5a-2e18-6061-22b7-5bd8eecbc563` | Real-time materialized rollups, 99x query speedup | **Passed ✓** |
| **3. Industrial IoT Simulation** | `01a11b5c-844d-86ce-9146-6afa2915c842` | Fleet sensor telemetry, anomaly detection, 5-min rollups | **Passed ✓** |
| **4. Real-Time Financial Ingestion** | `01a11b64-a4cd-bf31-7f19-8f2f8904f69d` | High-frequency trade micro-batches, 1-min OHLCV & VWAP | **Passed ✓** |
| **5. AI Vector Search (pgvector)** | `01a11b66-3a25-902e-3690-f9ea40cd5014` | 384-dim embeddings, HNSW index, Hybrid RAG search | **Passed ✓** |

---

## 🏗 Architecture & Modules

```
tiger-data/
├── 01_hypertable/
│   ├── schema.sql                 # DDL for system_metrics hypertable + compression
│   ├── verify_hypertable.py       # Chunk partitioning & exclusion verification
│   └── README.md
├── 02_continuous_aggregates/
│   ├── caggs_schema.sql           # Hourly & daily CAGG definitions + real-time policies
│   ├── test_caggs.py              # 99.1x query latency acceleration benchmark
│   └── README.md
├── 03_iot_telemetry/
│   ├── iot_schema.sql             # Industrial IoT hypertable + 5-min fleet rollups
│   ├── iot_simulator.py           # 40-device telemetry generator & anomaly engine
│   └── README.md
├── 04_financial_pipeline/
│   ├── market_schema.sql          # High-frequency trading hypertable (6h chunks)
│   ├── financial_streamer.py      # Live crypto trade streamer + OHLCV / VWAP engine
│   └── README.md
├── 05_pgvector_search/
│   ├── vector_schema.sql          # pgvector table + HNSW index + hybrid query
│   ├── pgvector_search.py         # AI incident triaging & cosine distance ranking
│   └── README.md
├── visual_reports/
│   └── index.html                 # Interactive multi-challenge Tiger Console UI
├── screenshots/                   # Verification proof screenshots for MLH submissions
├── run_all_challenges.py          # Master suite test runner
└── README.md
```

---

## ⚡ Quickstart & Verification

### 1. Run the Entire Suite
To run all 5 challenges and verify chunk creation, CAGG benchmarks, anomaly detection, financial streaming, and pgvector semantic searches:

```bash
python run_all_challenges.py
```

### 2. Run Individual Modules
```bash
# Challenge 1: Hypertable & Chunks
python 01_hypertable/verify_hypertable.py

# Challenge 2: Continuous Aggregates Benchmark (99x Speedup)
python 02_continuous_aggregates/test_caggs.py

# Challenge 3: Industrial IoT Telemetry Ingestion
python 03_iot_telemetry/iot_simulator.py

# Challenge 4: Real-Time Financial Ingestion & VWAP
python 04_financial_pipeline/financial_streamer.py

# Challenge 5: AI-Powered pgvector Semantic Search
python 05_pgvector_search/pgvector_search.py
```

---

## 🌟 Key Technical Implementations

### 1. Hypertables & Automatic Chunk Partitioning
- Automatic partitioning of time-series records into 1-day and 6-hour chunks.
- Chunk exclusion (`EXPLAIN ANALYZE`) guarantees that queries touching narrow time ranges avoid scanning unrelated chunks.
- Columnar compression automatically compresses historical chunks, saving ~88% of storage.

### 2. Continuous Aggregates with Real-Time Materialization
- Pre-computed 1-hour and 1-day rollups drastically reduce query execution times from ~50ms to 0.49ms (**99.1x faster**).
- Real-time views (`timescaledb.materialized_only = false`) seamlessly combine pre-computed historical rows with fresh un-materialized rows from active chunks.

### 3. High-Frequency Market Ingestion & VWAP
- Micro-batched ingestion of trade ticks across cryptocurrency and equities symbols.
- Continuous aggregate candlestick charts providing sub-second Volume-Weighted Average Price (VWAP) and OHLCV bars.

### 4. Hybrid AI RAG with `pgvector`
- Native vector storage in PostgreSQL with `vector(384)`.
- Sub-millisecond similarity queries powered by HNSW indexes using cosine distance `<=>`.
- Hybrid queries filtering by both semantic vector proximity and relational time/severity attributes without needing an external vector DB.

---

## 📜 License
MIT License. Created by [Farhan Mallik](https://github.com/farhanmallik05) for Global Hack Week: Hacktoberfest 2026.
