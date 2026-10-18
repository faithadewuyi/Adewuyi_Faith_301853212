
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