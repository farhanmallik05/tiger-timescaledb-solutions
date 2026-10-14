-- ============================================================================
-- Tiger Cloud / TimescaleDB Challenge 1: First Hypertable Setup
-- Challenge ID: 01a11b54-794b-ea57-035a-4e2b701feb8d
-- Description: Create a production hypertable for distributed systems metrics
-- ============================================================================

-- 1. Ensure TimescaleDB extension is active
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- 2. Create the base metrics table
DROP TABLE IF EXISTS system_metrics CASCADE;

CREATE TABLE system_metrics (
    time            TIMESTAMPTZ NOT NULL,
    host_id         VARCHAR(64) NOT NULL,
    datacenter      VARCHAR(32) NOT NULL,
    cluster         VARCHAR(32) NOT NULL,
    cpu_usage_pct   DOUBLE PRECISION CHECK (cpu_usage_pct >= 0 AND cpu_usage_pct <= 100),
    memory_used_gb  DOUBLE PRECISION CHECK (memory_used_gb >= 0),
    disk_io_mbps    DOUBLE PRECISION CHECK (disk_io_mbps >= 0),
    network_rx_mbps DOUBLE PRECISION CHECK (network_rx_mbps >= 0),
    network_tx_mbps DOUBLE PRECISION CHECK (network_tx_mbps >= 0),
    load_average    DOUBLE PRECISION,
    status          VARCHAR(16) DEFAULT 'HEALTHY'
);

-- 3. Convert into TimescaleDB Hypertable with 1-day chunk time intervals
-- This enables automatic time-based partitioning under the hood.
SELECT create_hypertable(
    'system_metrics',
    'time',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- 4. Create optimized composite index for time-series filtering
CREATE INDEX IF NOT EXISTS idx_system_metrics_host_time
    ON system_metrics (host_id, time DESC);

CREATE INDEX IF NOT EXISTS idx_system_metrics_dc_time
    ON system_metrics (datacenter, time DESC);

-- 5. Enable native TimescaleDB chunk compression policy
-- Automatically compresses data older than 3 days by host and datacenter
ALTER TABLE system_metrics SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'datacenter, host_id',
    timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('system_metrics', INTERVAL '3 days', if_not_exists => TRUE);

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Inspect Hypertable metadata
SELECT 
    hypertable_name,
    num_chunks,
    total_chunks,
    compression_enabled
FROM timescaledb_information.hypertables
WHERE hypertable_name = 'system_metrics';

-- Inspect Chunks and Time Ranges
SELECT 
    chunk_name,
    range_start,
    range_end,
    is_compressed
FROM timescaledb_information.chunks
WHERE hypertable_name = 'system_metrics'
ORDER BY range_start DESC;

-- Sample Analytical Query utilizing Chunk Exclusion
EXPLAIN ANALYZE
SELECT 
    time_bucket('1 hour', time) AS hour_bucket,
    host_id,
    avg(cpu_usage_pct) AS avg_cpu,
    max(cpu_usage_pct) AS peak_cpu,
    avg(memory_used_gb) AS avg_mem,
    avg(disk_io_mbps) AS avg_io
FROM system_metrics
WHERE time >= NOW() - INTERVAL '2 days'
  AND datacenter = 'us-east-1'
GROUP BY hour_bucket, host_id
ORDER BY hour_bucket DESC, avg_cpu DESC;
