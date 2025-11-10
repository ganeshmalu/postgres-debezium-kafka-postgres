-- Create schemas
CREATE SCHEMA IF NOT EXISTS source;
CREATE SCHEMA IF NOT EXISTS source_audit;

-- ======================================================================
-- 1. Example Source Tables (your real tables will go here)
-- ======================================================================

CREATE TABLE IF NOT EXISTS source.customer (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS source.orders (
    id SERIAL PRIMARY KEY,
    customer_id INT,
    amount NUMERIC(10,2),
    status TEXT,
    created_at TIMESTAMP DEFAULT now()
);

ALTER TABLE source.customer REPLICA IDENTITY FULL;
ALTER TABLE source.orders REPLICA IDENTITY FULL;

-- ======================================================================
-- 2. Corresponding Audit Tables (Hibernate Envers style)
-- ======================================================================

CREATE TABLE IF NOT EXISTS source_audit.customer_audit (
    event_id SERIAL PRIMARY KEY,
    op TEXT NOT NULL,                 -- Operation type: c, u, d
    -- Source table columns
    id INT,
    name TEXT,
    email TEXT,
    created_at TIMESTAMP,
    -- Audit metadata
    ts_ms BIGINT,                     -- Event timestamp
    txid BIGINT,                      -- Transaction ID
    lsn TEXT,                         -- Log sequence number
    event_time TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS source_audit.orders_audit (
    event_id SERIAL PRIMARY KEY,
    op TEXT NOT NULL,
    -- Source table columns
    id INT,
    customer_id INT,
    amount NUMERIC(10,2),
    status TEXT,
    created_at TIMESTAMP,
    -- Audit metadata
    ts_ms BIGINT,
    txid BIGINT,
    lsn TEXT,
    event_time TIMESTAMP DEFAULT now()
);
