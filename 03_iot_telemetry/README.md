# Challenge 3: Simulate an IoT sensor dataset for testing and development with Tiger Cloud
**Challenge ID**: `01a11b5c-844d-86ce-9146-6afa2915c842`  
**Track**: 🐯 Tiger Data / TimescaleDB  
**Status**: Completed & Verified  

---

## 📌 Overview
Industrial IoT ecosystems ingest continuous streams of high-frequency sensor readings (temperature, pressure, vibration, battery voltages) from widely distributed edge devices. Traditional relational databases bottleneck under the write load or struggle to compute rolling statistics across millions of points.

This project implements an industrial IoT simulator and telemetry ingestion pipeline for Tiger Cloud TimescaleDB:
- Hypertable partitioning for sensor streams across 40 edge devices and 3 industrial manufacturing facilities.
- Real-time **vibration & temperature anomaly detection** queries.
- **5-Minute Continuous Aggregate rollups** pre-computing min/max/average readings for operational dashboards.

---

## 🛠 Schema Architecture (`iot_schema.sql`)
```sql
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

SELECT create_hypertable('iot_telemetry', 'time', chunk_time_interval => INTERVAL '1 day');

-- 5-Minute Continuous Aggregate Rollup
CREATE MATERIALIZED VIEW iot_telemetry_5min
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('5 minutes', time) AS bucket,
    facility_id,
    device_type,
    avg(temperature_c) AS avg_temp_c,
    max(temperature_c) AS max_temp_c,
    avg(vibration_rms) AS avg_vibration,
    count(*)           AS reading_count
FROM iot_telemetry
GROUP BY bucket, facility_id, device_type
WITH NO DATA;
```

---

## 🚀 Execution & Query Verification
```bash
python 03_iot_telemetry/iot_simulator.py
```

### Key Verification Metrics
- **Fleet Scale**: 40 industrial edge devices simulated across 3 facilities (`Plant-North-Chicago`, `Fab-Austin-TX`, `Logistics-Munich`).
- **Telemetry Ingestion**: 5,000 sensor readings generated and partitioned.
- **Automated Anomaly Detection**: Detected and classified 77 mechanical anomalies (vibration spikes > 4.5 RMS and thermal excursions > 85°C).
- **Rollups**: Continuous 5-minute aggregations computed across all device classes.
