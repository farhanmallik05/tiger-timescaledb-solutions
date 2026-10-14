-- ============================================================================
-- Tiger Cloud / TimescaleDB Challenge 2: Continuous Aggregates (CAGGs)
-- Challenge ID: 01a11b5a-2e18-6061-22b7-5bd8eecbc563
-- Description: Materialized real-time continuous aggregate view with time bucketing
-- ============================================================================

-- 1. Create Hourly Continuous Aggregate for Dashboards
DROP MATERIALIZED VIEW IF EXISTS system_metrics_hourly CASCADE;

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
    max(memory_used_gb) AS max_memory_gb,
    avg(disk_io_mbps) AS avg_disk_io,
    sum(network_rx_mbps) AS total_network_rx,
    sum(network_tx_mbps) AS total_network_tx,
    count(*) AS sample_count
FROM system_metrics
GROUP BY bucket, datacenter, host_id
WITH NO DATA;

-- 2. Configure Real-Time Aggregation
-- Enables combining pre-computed materialized historical buckets with live,
-- un-materialized raw data from the current active chunk on the fly.
ALTER MATERIALIZED VIEW system_metrics_hourly SET (
    timescaledb.materialized_only = false
);

-- 3. Add Automated Continuous Aggregate Policy
-- Schedules the background worker to continuously refresh materialized buckets
SELECT add_continuous_aggregate_policy(
    'system_metrics_hourly',
    start_offset      => INTERVAL '30 days',
    end_offset        => INTERVAL '1 hour',
    schedule_interval => INTERVAL '30 minutes',
    if_not_exists     => TRUE
);

-- 4. Create Daily Rollup CAGG (Hierarchical Continuous Aggregate)
-- TimescaleDB allows continuous aggregates on top of continuous aggregates!
DROP MATERIALIZED VIEW IF EXISTS system_metrics_daily CASCADE;

CREATE MATERIALIZED VIEW system_metrics_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', bucket) AS day_bucket,
    datacenter,
    avg(avg_cpu) AS daily_avg_cpu,
    max(max_cpu) AS daily_peak_cpu,
    avg(avg_memory_gb) AS daily_avg_mem,
    sum(total_network_rx) AS daily_net_rx,
    sum(total_network_tx) AS daily_net_tx,
    sum(sample_count) AS daily_samples
FROM system_metrics_hourly
GROUP BY day_bucket, datacenter
WITH NO DATA;

-- ============================================================================
-- Dashboard Acceleration Benchmark Queries
-- ============================================================================

-- A. Unaccelerated Raw Query (Scans raw hypertable chunks)
EXPLAIN ANALYZE
SELECT
    time_bucket('1 hour', time) AS bucket,
    datacenter,
    avg(cpu_usage_pct) AS avg_cpu,
    max(cpu_usage_pct) AS max_cpu
FROM system_metrics
WHERE time >= NOW() - INTERVAL '14 days'
GROUP BY bucket, datacenter
ORDER BY bucket DESC;

-- B. Accelerated Continuous Aggregate Query (Reads pre-computed summary)
EXPLAIN ANALYZE
SELECT
    bucket,
    datacenter,
    avg_cpu,
    max_cpu
FROM system_metrics_hourly
WHERE bucket >= NOW() - INTERVAL '14 days'
ORDER BY bucket DESC;
