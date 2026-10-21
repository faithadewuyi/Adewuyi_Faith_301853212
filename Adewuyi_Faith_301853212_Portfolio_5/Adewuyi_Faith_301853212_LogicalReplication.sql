-- Portfolio 5: Distributed and Cloud Database Exercise
-- Case Study: Abitim Farms Management System
-- Database System: PostgreSQL 18
--
-- This script documents the logical replication implementation
-- completed for Portfolio 5.
--
-- IMPORTANT:
-- The commands are grouped according to the database on which
-- they were executed. This file is documentation of the completed
-- implementation and should not be executed from top to bottom
-- against the existing setup because the databases, publication,
-- replication slot and subscription already exist.


-- ============================================================
-- 1. SERVER CONFIGURATION
-- ============================================================
-- PostgreSQL logical replication requires wal_level = logical.
-- The following setting was configured in postgresql.conf:
--
-- wal_level = logical
--
-- The PostgreSQL service was restarted and the setting verified
-- using:

SHOW wal_level;

-- Other replication-related settings were checked using:

SHOW max_replication_slots;
SHOW max_wal_senders;
SHOW max_logical_replication_workers;


-- ============================================================
-- 2. CREATE PORTFOLIO 5 DATABASES
-- Run while connected to the postgres database.
-- ============================================================

CREATE DATABASE abitim_farms_primary;
CREATE DATABASE abitim_farms_replica;


-- ============================================================
-- 3. PRIMARY DATABASE TABLE
-- Run while connected to abitim_farms_primary.
-- ============================================================

CREATE TABLE products (
    product_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(30) NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL,
    quantity_in_stock INTEGER NOT NULL DEFAULT 0
);


-- ============================================================
-- 4. REPLICA DATABASE TABLE
-- Run while connected to abitim_farms_replica.
-- ============================================================
-- PostgreSQL logical replication replicates data changes but does
-- not automatically create the destination table structure.
-- Therefore, the matching products table was created manually.

CREATE TABLE products (
    product_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(30) NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL,
    quantity_in_stock INTEGER NOT NULL DEFAULT 0
);


-- ============================================================
-- 5. PUBLICATION
-- Run while connected to abitim_farms_primary.
-- ============================================================

CREATE PUBLICATION abitim_farms_publication
FOR TABLE products;


-- ============================================================
-- 6. LOGICAL REPLICATION SLOT
-- Run while connected to abitim_farms_primary.
-- ============================================================

SELECT *
FROM pg_create_logical_replication_slot(
    'abitim_farms_slot',
    'pgoutput'
);


-- ============================================================
-- 7. SUBSCRIPTION
-- Run while connected to abitim_farms_replica.
-- ============================================================
-- The actual password is intentionally omitted from this portfolio.
-- <POSTGRES_PASSWORD> represents the local PostgreSQL password.

CREATE SUBSCRIPTION abitim_farms_subscription
CONNECTION 'host=localhost port=5432 dbname=abitim_farms_primary user=postgres password=<POSTGRES_PASSWORD>'
PUBLICATION abitim_farms_publication
WITH (
    create_slot = false,
    slot_name = 'abitim_farms_slot',
    copy_data = false
);


-- ============================================================
-- 8. INSERT REPLICATION TEST
-- Run while connected to abitim_farms_primary.
-- ============================================================

INSERT INTO products (
    product_name,
    category,
    unit_price,
    quantity_in_stock
)
VALUES (
    'Crate of Eggs',
    'eggs',
    4500.00,
    100
);

SELECT * FROM products;


-- ============================================================
-- 9. VERIFY INSERT ON REPLICA
-- Run while connected to abitim_farms_replica.
-- ============================================================

SELECT * FROM products;


-- ============================================================
-- 10. UPDATE REPLICATION TEST
-- Run while connected to abitim_farms_primary.
-- ============================================================

UPDATE products
SET quantity_in_stock = 85
WHERE product_name = 'Crate of Eggs';

SELECT * FROM products;


-- ============================================================
-- 11. VERIFY UPDATE ON REPLICA
-- Run while connected to abitim_farms_replica.
-- ============================================================

SELECT * FROM products;


-- ============================================================
-- 12. SUBSCRIPTION STATUS
-- Run while connected to abitim_farms_replica.
-- ============================================================

SELECT
    subname,
    pid,
    received_lsn,
    latest_end_lsn
FROM pg_stat_subscription;


-- ============================================================
-- 13. PUBLICATION AND REPLICATION SLOT STATUS
-- Run while connected to abitim_farms_primary.
-- ============================================================

SELECT
    p.pubname,
    s.slot_name,
    s.plugin,
    s.slot_type,
    s.active
FROM pg_publication p
CROSS JOIN pg_replication_slots s
WHERE p.pubname = 'abitim_farms_publication'
  AND s.slot_name = 'abitim_farms_slot';