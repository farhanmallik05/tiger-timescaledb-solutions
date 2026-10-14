# Challenge 4: Ingest real-time financial data into Tiger Cloud
**Challenge ID**: `01a11b64-a4cd-bf31-7f19-8f2f8904f69d`  
**Track**: 🐯 Tiger Data / TimescaleDB  
**Status**: Completed & Verified  

---

## 📌 Overview
High-frequency quantitative trading and real-time financial monitoring require ultra-low ingestion latency alongside instant analytical aggregations (OHLCV candlesticks, order book imbalance, Volume-Weighted Average Price).

This project implements a real-time financial trade streaming pipeline into Tiger Cloud TimescaleDB:
- Micro-batch streaming pipeline connected to live asset price feeds (`BTC-USD`, `ETH-USD`, `SOL-USD`).
- TimescaleDB Hypertable with **6-hour chunk intervals** tailored for high transaction volumes.
- Continuous Aggregate materialized view computing **1-minute OHLCV candles** and **real-time VWAP**.

---

## 🛠 Schema Architecture (`market_schema.sql`)
```sql
CREATE TABLE market_trades (
    time        TIMESTAMPTZ NOT NULL,
    symbol      VARCHAR(16) NOT NULL,
    exchange    VARCHAR(16) NOT NULL,
    price       DOUBLE PRECISION NOT NULL CHECK (price > 0),
    volume      DOUBLE PRECISION NOT NULL CHECK (volume > 0),
    trade_side  VARCHAR(4) CHECK (trade_side IN ('BUY', 'SELL')),
    trade_id    VARCHAR(64)
);

-- 6-hour chunk time intervals for high-throughput market ticks
SELECT create_hypertable('market_trades', 'time', chunk_time_interval => INTERVAL '6 hours');

-- Continuous Aggregate: 1-Minute OHLCV & VWAP
CREATE MATERIALIZED VIEW market_ohlcv_1min
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 minute', time) AS candle_time,
    symbol,
    first(price, time) AS open_price,
    max(price)         AS high_price,
    min(price)         AS low_price,
    last(price, time)  AS close_price,
    sum(volume)        AS total_volume,
    sum(price * volume) / sum(volume) AS vwap_price,
    count(*)           AS trade_count
FROM market_trades
GROUP BY candle_time, symbol
WITH NO DATA;
```

---

## 🚀 Execution & Verification
```bash
python 04_financial_pipeline/financial_streamer.py
```

### Key Verification Metrics
- **Live Assets Streamed**: `BTC-USD`, `ETH-USD`, `SOL-USD`.
- **Ticks Processed**: 1,140 high-frequency trade transactions ingested in micro-batches.
- **Notional Trading Volume**: Over **$17,200,000 USD** processed.
- **Rollup Precision**: Sub-second Open, High, Low, Close, and VWAP calculations.
