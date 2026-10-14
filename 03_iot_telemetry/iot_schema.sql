-- ============================================================================
-- Tiger Cloud / TimescaleDB Challenge 3: IoT Sensor Dataset Simulation
-- Challenge ID: 01a11b5c-844d-86ce-9146-6afa2915c842
-- Description: Ingest & analyze simulated IoT device telemetry on Tiger Cloud
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- 1. Create IoT Telemetry Table
DROP TABLE IF EXISTS iot_telemetry CASCADE;

CREATE TABLE iot_telemetry (
    time            TIMESTAMPTZ NOT NULL,
    device_id       VARCHAR(32) NOT NULL,
    device_type     VARCHAR(32) NOT NULL,
    facility_id     VARCHAR(32) NOT NULL,
    temperature_c   DOUBLE PRECISION,
    humidity_pct    DOUBLE PRECISION,
    pressure_kpa    DOUBLE PRECISION,
    battery_pct     DOUBLE PRECISION,
    vibration_rms   DOUBLE PRECISION,
    error_flags     INTEGER DEFAULT 0,
    firmware_ver    VARCHAR(16) DEFAULT 'v2.4.1'
);

-- 2. Convert to Hypertable with 1-Day Chunks
SELECT create_hypertable(
    'iot_telemetry',
    'time',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- 3. Composite Indexes for Sensor Lookup
CREATE INDEX IF NOT EXISTS idx_iot_dev_time ON iot_telemetry (device_id, time DESC);
CREATE INDEX IF NOT EXISTS idx_iot_fac_time ON iot_telemetry (facility_id, time DESC);

-- 4. Continuous Aggregate: 5-Minute IoT Device Telemetry Rollup
DROP MATERIALIZED VIEW IF EXISTS iot_telemetry_5min CASCADE;

CREATE MATERIALIZED VIEW iot_telemetry_5min
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('5 minutes', time) AS bucket,
    facility_id,
    device_type,
    avg(temperature_c) AS avg_temp_c,
    max(temperature_c) AS max_temp_c,
    avg(vibration_rms) AS avg_vibration,
    max(vibration_rms) AS peak_vibration,
    min(battery_pct)   AS min_battery,
    count(*)           AS reading_count
FROM iot_telemetry
GROUP BY bucket, facility_id, device_type
WITH NO DATA;

-- 5. Automated Refresh Policy for 5-Minute Rollup
SELECT add_continuous_aggregate_policy(
    'iot_telemetry_5min',
    start_offset      => INTERVAL '7 days',
    end_offset        => INTERVAL '5 minutes',
    schedule_interval => INTERVAL '5 minutes',
    if_not_exists     => TRUE
);

-- ============================================================================
-- IoT Operational Analytical Queries
-- ============================================================================

-- A. Anomaly Detection: Detect Mechanical Equipment Vibrations Exceeding Threshold
SELECT 
    time,
    device_id,
    facility_id,
    vibration_rms,
    temperature_c,
    CASE 
        WHEN vibration_rms > 4.5 THEN 'CRITICAL VIBRATION SPIKE'
        WHEN temperature_c > 85.0 THEN 'OVERHEATING EXTREME'
        ELSE 'WARNING'
    END AS alert_severity
FROM iot_telemetry
WHERE time >= NOW() - INTERVAL '24 hours'
  AND (vibration_rms > 4.5 OR temperature_c > 85.0)
ORDER BY vibration_rms DESC
LIMIT 20;

-- B. Battery Fleet Depletion Health Report
SELECT 
    device_id,
    facility_id,
    min(battery_pct) AS current_battery_pct,
    max(battery_pct) - min(battery_pct) AS daily_drain_rate
FROM iot_telemetry
WHERE time >= NOW() - INTERVAL '24 hours'
GROUP BY device_id, facility_id
HAVING min(battery_pct) < 20.0
ORDER BY current_battery_pct ASC;
