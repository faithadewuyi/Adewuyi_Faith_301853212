-- Portfolio 3: Transactions and Concurrency
-- Case Study: Abitim Farms Management System
-- Database: PostgreSQL

-- This script demonstrates transaction management and concurrency control
-- using the existing Abitim Farms database.

-- Prerequisites:
-- This portfolio uses the Abitim Farms database created in Portfolio 1
-- and test product records generated during Portfolio 2.
--
-- Expected starting values for the documented demonstrations:
-- Crate of Eggs   = 100
-- Test Product 10 = 8
-- Test Product 20 = 20
--
-- NOTE:
-- The COMMIT and concurrency demonstrations intentionally modify data.
-- Therefore, rerunning those demonstrations without resetting the test
-- records will produce different quantities from the documented results.

-- Step 2: Check initial stock before transaction demonstrations
SELECT
    product_id,
    product_name,
    unit_price,
    quantity_in_stock
FROM products
WHERE product_name = 'Crate of Eggs';

-- Step 3: Demonstrate ROLLBACK
BEGIN;

UPDATE products
SET quantity_in_stock = quantity_in_stock - 10
WHERE product_name = 'Crate of Eggs';

-- Check the value inside the transaction
SELECT
    product_name,
    quantity_in_stock AS stock_before_rollback
FROM products
WHERE product_name = 'Crate of Eggs';

ROLLBACK;

-- Verify that the uncommitted change was cancelled
SELECT
    product_name,
    quantity_in_stock AS stock_after_rollback
FROM products
WHERE product_name = 'Crate of Eggs';

-- Step 4: Check the current transaction isolation level
SHOW transaction_isolation;

-- Step 5: Demonstrate COMMIT

-- Check stock before the transaction
SELECT
    product_name,
    quantity_in_stock AS stock_before_commit
FROM products
WHERE product_name = 'Test Product 10';

BEGIN;

UPDATE products
SET quantity_in_stock = quantity_in_stock - 2
WHERE product_name = 'Test Product 10'
RETURNING
    product_name,
    quantity_in_stock;

COMMIT;

-- Verify that the committed change remains
SELECT
    product_name,
    quantity_in_stock AS stock_after_commit
FROM products
WHERE product_name = 'Test Product 10';

-- IMPORTANT:
-- The concurrency demonstration below requires two independent
-- Session B uses pgAdmin's autocommit behaviour for its standalone UPDATE.
-- Therefore, after the waiting UPDATE completes, its change is committed
-- automatically and no separate COMMIT is required in Session B.
-- pgAdmin Query Tool sessions connected to the same database.
-- Do not execute the entire Step 6 section as one script.
--
-- Execution order:
-- 1. In Session A, execute BEGIN and the UPDATE only.
-- 2. Leave Session A's transaction open.
-- 3. In Session B, execute the SELECT and observe the last committed value.
-- 4. In Session B, execute the UPDATE. It should wait because
--    Session A holds a row-level lock on the same product row.
-- 5. Return to Session A and execute COMMIT.
-- 6. Session B's waiting UPDATE then completes.
-- 7. Verify the final quantity in Session B.

-- Step 6: Demonstrate concurrency control using two database sessions
-- Test Product 20 had an initial quantity_in_stock of 20.

-- =========================
-- SESSION A
-- =========================

BEGIN;

-- Update the product but leave the transaction uncommitted.
-- This changes the value from 20 to 18 in Session A
-- and holds a row-level lock on the selected product.
UPDATE products
SET quantity_in_stock = quantity_in_stock - 2
WHERE product_name = 'Test Product 20'
RETURNING
    product_name,
    quantity_in_stock;

-- Do not COMMIT immediately.
-- While this transaction remains open, execute the
-- Session B statements in a separate Query Tool.


-- =========================
-- SESSION B
-- =========================

-- Session B still sees the last committed value (20)
-- because Session A's value of 18 is not yet committed.
SELECT
    product_name,
    quantity_in_stock
FROM products
WHERE product_name = 'Test Product 20';

-- This UPDATE waits because Session A currently holds
-- a row-level lock on the same product row.
UPDATE products
SET quantity_in_stock = quantity_in_stock - 1
WHERE product_name = 'Test Product 20'
RETURNING
    product_name,
    quantity_in_stock;


-- =========================
-- RETURN TO SESSION A
-- =========================

-- Commit Session A to save its change and release the row lock.
COMMIT;


-- =========================
-- SESSION B RESULT
-- =========================

-- After Session A commits, the waiting UPDATE in Session B
-- continues and updates the newly committed value from 18 to 17.

-- Final verification after the waiting UPDATE completes
SELECT
    product_name,
    quantity_in_stock AS final_stock
FROM products
WHERE product_name = 'Test Product 20';