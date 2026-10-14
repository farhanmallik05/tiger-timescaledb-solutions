-- ============================================================================
-- Tiger Cloud / TimescaleDB Challenge 4: Real-Time Financial Pipeline
-- Challenge ID: 01a11b64-a4cd-bf31-7f19-8f2f8904f69d
-- Description: Stream financial & market trade data into a Tiger Cloud hypertable
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- 1. Create Raw Trades Table
DROP TABLE IF EXISTS market_trades CASCADE;

CREATE TABLE market_trades (
    time        TIMESTAMPTZ NOT NULL,
    symbol      VARCHAR(16) NOT NULL,
    exchange    VARCHAR(16) NOT NULL,
    price       DOUBLE PRECISION NOT NULL CHECK (price > 0),
    volume      DOUBLE PRECISION NOT NULL CHECK (volume > 0),
    trade_side  VARCHAR(4) CHECK (trade_side IN ('BUY', 'SELL')),
    trade_id    VARCHAR(64)
);

-- 2. Convert to Hypertable with 6-hour chunk time intervals (optimized for high-frequency trading)
SELECT create_hypertable(
    'market_trades',
    'time',
    chunk_time_interval => INTERVAL '6 hours',
    if_not_exists => TRUE
);

-- 3. Composite Indexes for Symbol Lookups
CREATE INDEX IF NOT EXISTS idx_market_sym_time ON market_trades (symbol, time DESC);

-- 4. Continuous Aggregate: 1-Minute Real-Time OHLCV & VWAP Candlestick Chart
DROP MATERIALIZED VIEW IF EXISTS market_ohlcv_1min CASCADE;

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

-- 5. Real-Time View Configuration
ALTER MATERIALIZED VIEW market_ohlcv_1min SET (
    timescaledb.materialized_only = false
);

-- 6. Automated Policy
SELECT add_continuous_aggregate_policy(
    'market_ohlcv_1min',
    start_offset      => INTERVAL '24 hours',
    end_offset        => INTERVAL '1 minute',
    schedule_interval => INTERVAL '1 minute',
    if_not_exists     => TRUE
);

-- ============================================================================
-- Financial Analytics Queries
-- ============================================================================

-- A. Recent 1-Minute Candles with Volume Weighted Average Price (VWAP)
SELECT 
    candle_time,
    symbol,
    open_price,
    high_price,
    low_price,
    close_price,
    round(total_volume::numeric, 4) AS volume,
    round(vwap_price::numeric, 2)   AS vwap,
    trade_count
FROM market_ohlcv_1min
WHERE candle_time >= NOW() - INTERVAL '30 minutes'
ORDER BY candle_time DESC, symbol;

-- B. 15-Minute Rolling Volatility & Order Flow Imbalance
SELECT
    time_bucket('15 minutes', time) AS window_time,
    symbol,
    stddev(price) AS price_volatility,
    sum(CASE WHEN trade_side = 'BUY' THEN volume ELSE -volume END) AS net_order_flow
FROM market_trades
WHERE time >= NOW() - INTERVAL '4 hours'
GROUP BY window_time, symbol
ORDER BY window_time DESC;
