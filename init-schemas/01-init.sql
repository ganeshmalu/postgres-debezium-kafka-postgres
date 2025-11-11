-- Create schemas
CREATE SCHEMA IF NOT EXISTS cep_core;
CREATE SCHEMA IF NOT EXISTS cep_core_audit;

-- ======================================================================
-- 1. Example Source Tables
-- ======================================================================

CREATE TABLE IF NOT EXISTS cep_core.customer (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    created_by VARCHAR(255),
    modified_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT now(),
    modified_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cep_core.orders (
    id SERIAL PRIMARY KEY,
    customer_id INT,
    amount NUMERIC(10,2),
    status TEXT,
    created_by VARCHAR(255),
    modified_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT now(),
    modified_at TIMESTAMP DEFAULT now()
);

ALTER TABLE cep_core.customer REPLICA IDENTITY FULL;
ALTER TABLE cep_core.orders REPLICA IDENTITY FULL;

-- ======================================================================
-- 2. Corresponding Audit Tables
-- ======================================================================

CREATE TABLE IF NOT EXISTS cep_core_audit.customer_audit (
    event_id SERIAL PRIMARY KEY,
    op TEXT NOT NULL,                 -- Operation type: c, u, d
    id INT,
    name TEXT,
    email TEXT,
    created_by VARCHAR(255),
    modified_by VARCHAR(255),
    created_at TIMESTAMP,
    modified_at TIMESTAMP,
    -- Audit metadata
    ts_ms BIGINT,                     -- Event timestamp (milliseconds) - used to calculate event_time
    txid BIGINT,                      -- Transaction ID
    lsn TEXT,                         -- Log sequence number
    event_time TIMESTAMP              -- Will be set from ts_ms via trigger
);

CREATE TABLE IF NOT EXISTS cep_core_audit.orders_audit (
    event_id SERIAL PRIMARY KEY,
    op TEXT NOT NULL,
    id INT,
    customer_id INT,
    amount NUMERIC(10,2),
    status TEXT,
    created_by VARCHAR(255),
    modified_by VARCHAR(255),
    created_at TIMESTAMP,
    modified_at TIMESTAMP,
    -- Audit metadata
    ts_ms BIGINT,                     -- Event timestamp (milliseconds) - used to calculate event_time
    txid BIGINT,
    lsn TEXT,
    event_time TIMESTAMP              -- Will be set from ts_ms via trigger
);

-- ======================================================================
-- 3. Triggers to set event_time from ts_ms
-- ======================================================================

-- Function to set event_time from ts_ms
CREATE OR REPLACE FUNCTION cep_core_audit.set_event_time() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ts_ms IS NOT NULL THEN
        NEW.event_time := to_timestamp(NEW.ts_ms / 1000.0);
    ELSE
        NEW.event_time := now();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for customer_audit
DROP TRIGGER IF EXISTS trg_set_event_time_customer ON cep_core_audit.customer_audit;
CREATE TRIGGER trg_set_event_time_customer
    BEFORE INSERT ON cep_core_audit.customer_audit
    FOR EACH ROW
    EXECUTE FUNCTION cep_core_audit.set_event_time();

-- Trigger for orders_audit
DROP TRIGGER IF EXISTS trg_set_event_time_orders ON cep_core_audit.orders_audit;
CREATE TRIGGER trg_set_event_time_orders
    BEFORE INSERT ON cep_core_audit.orders_audit
    FOR EACH ROW
    EXECUTE FUNCTION cep_core_audit.set_event_time();
