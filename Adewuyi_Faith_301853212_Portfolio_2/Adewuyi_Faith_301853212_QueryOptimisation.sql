-- Portfolio 2: Query Processing and Optimisation
-- Case Study: Abitim Farms Management System
--
-- Reproduction Notes:
-- This script assumes that the Portfolio 1 database schema and original
-- sample data have already been created.
--
-- The performance experiment begins with the category index absent.
-- The test-data INSERT should be executed only once because product_name
-- has a UNIQUE constraint. Re-running the INSERT will attempt to create
-- duplicate test-product names.
--
-- CREATE INDEX idx_products_category should also be executed only once
-- unless the index has first been removed.
--
-- The SQL statements are retained in this file as evidence of the
-- queries used during the Portfolio 2 implementation.
-- Query 1: Retrieve products in the poultry category
SELECT *
FROM products
WHERE category = 'poultry';

-- Step 4: Generate test data for query optimisation analysis
INSERT INTO products (
    product_name,
    category,
    unit_price,
    quantity_in_stock
)
SELECT
    'Test Product ' || number,
    CASE
        WHEN number % 100 = 0 THEN 'poultry'
        WHEN number % 3 = 0 THEN 'eggs'
        WHEN number % 3 = 1 THEN 'feed'
        ELSE 'other'
    END,
    (1000 + (number % 10000))::NUMERIC(12,2),
    (number % 200)
FROM generate_series(1, 5000) AS number;

-- Verify total number of products
SELECT COUNT(*) AS total_products
FROM products;

-- Check distribution of products by category
SELECT category, COUNT(*) AS number_of_products
FROM products
GROUP BY category
ORDER BY category;

-- Step 5: Execution plan on larger dataset before indexing
EXPLAIN ANALYZE
SELECT *
FROM products
WHERE category = 'poultry';
-- Step 6: Create an index on the product category column
CREATE INDEX idx_products_category
ON products(category);

-- Step 7: Execution plan after creating the category index
EXPLAIN ANALYZE
SELECT *
FROM products
WHERE category = 'poultry';

-- Step 8: Repeated performance test after indexing
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM products
WHERE category = 'poultry';
-- Step 9: Calculate the total value of each sale using joins and aggregation
SELECT
    s.sale_id,
    c.full_name AS customer,
    s.sale_date,
    s.payment_status,
    SUM(si.quantity * si.unit_price_at_sale) AS total_amount
FROM sales s
JOIN customers c
    ON c.customer_id = s.customer_id
JOIN sale_items si
    ON si.sale_id = s.sale_id
GROUP BY
    s.sale_id,
    c.full_name,
    s.sale_date,
    s.payment_status
ORDER BY s.sale_id;

-- Step 10: Analyse the execution plan of the sales JOIN query
EXPLAIN ANALYZE
SELECT
    s.sale_id,
    c.full_name AS customer,
    s.sale_date,
    s.payment_status,
    SUM(si.quantity * si.unit_price_at_sale) AS total_amount
FROM sales s
JOIN customers c
    ON c.customer_id = s.customer_id
JOIN sale_items si
    ON si.sale_id = s.sale_id
GROUP BY
    s.sale_id,
    c.full_name,
    s.sale_date,
    s.payment_status
ORDER BY s.sale_id;