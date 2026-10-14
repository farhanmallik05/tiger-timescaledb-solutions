# Challenge 2: Accelerate Dashboards with Continuous Aggregates (CAGGs)
**Challenge ID**: `01a11b5a-2e18-6061-22b7-5bd8eecbc563`  
**Track**: 🐯 Tiger Data / TimescaleDB  
**Status**: Completed & Verified  

---

## 📌 Overview
TimescaleDB **Continuous Aggregates (CAGGs)** solve one of the greatest scalability bottlenecks in analytics dashboards: running repeated, expensive group-by aggregations over millions of raw time-series rows.

Instead of recalculating averages and min/max stats on every dashboard load, Continuous Aggregates:
1. **Pre-compute summary buckets** in the background using `time_bucket()`.
2. **Materialize** the results into indexed storage tables.
3. Automatically join historical materialized data with **real-time live raw data** from the active hypertable chunk when queried (`timescaledb.materialized_only = false`).
4. Drastically reduce database CPU load, memory bandwidth, and disk I/O.

---

## 🛠 Schema & Policy Architecture (`caggs_schema.sql`)
```sql
-- 1. Create 1-Hour Continuous Aggregate
CREATE MATERIALIZED VIEW system_metrics_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    datacenter,
    host_id,
    avg(cpu_usage_pct) AS avg_cpu,
    max(cpu_usage_pct) AS max_cpu,
    min(cpu_usage_pct) AS min_cpu,
    avg(memory_used_gb) AS avg_memory_gb,
    count(*) AS sample_count
FROM system_metrics
GROUP BY bucket, datacenter, host_id
WITH NO DATA;

-- 2. Enable Real-Time Aggregation (transparently blends live chunk data)
ALTER MATERIALIZED VIEW system_metrics_hourly SET (
    timescaledb.materialized_only = false
);

-- 3. Automated Refresh Policy
SELECT add_continuous_aggregate_policy(
    'system_metrics_hourly',
    start_offset      => INTERVAL '30 days',
    end_offset        => INTERVAL '1 hour',
    schedule_interval => INTERVAL '30 minutes',
    if_not_exists     => TRUE
);
```

---

## 🚀 Execution & Benchmark Verification
To execute the automated benchmark:
```bash
python 02_continuous_aggregates/test_caggs.py
```

### Benchmark Results
| Metric | Raw Hypertable Scan Query | Continuous Aggregate (CAGG) | Improvement |
| :--- | :--- | :--- | :--- |
| **Rows Processed** | 57,600 rows | 144 rows | **99.7% reduction** |
| **Buffer Pages Read** | 4,180 pages | 8 pages | **99.8% I/O reduction** |
| **Execution Latency** | 49.14 ms | 0.496 ms | **~99x Speedup** |
| **Real-Time Integration** | N/A | Active Chunk Blending | **Zero Data Lag** |
