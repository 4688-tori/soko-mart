-- =====================================================
-- Q21: READ A QUERY PLAN
-- STEP 1: EXPLAIN ANALYZE WITH BUFFERS
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(i.line_total) AS revenue
FROM sokomart.customers c
JOIN sokomart.orders o
    ON o.customer_id = c.customer_id
JOIN sokomart.order_items i
    ON i.order_id = o.order_id
WHERE c.county = 'Kisumu'
  AND o.order_status = 'completed'
  AND o.order_date >= '2026-09-01'
  AND o.order_date < '2026-10-01'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY revenue DESC;

-- =====================================================
-- Q21: READ A QUERY PLAN
-- STEP 2: RUN KISUMU DASHBOARD QUERY
-- =====================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(i.line_total) AS revenue
FROM sokomart.customers c
JOIN sokomart.orders o
    ON o.customer_id = c.customer_id
JOIN sokomart.order_items i
    ON i.order_id = o.order_id
WHERE c.county = 'Kisumu'
  AND o.order_status = 'completed'
  AND o.order_date >= '2026-09-01'
  AND o.order_date < '2026-10-01'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY revenue DESC;
/*
Q21: EXECUTION PLAN ANALYSIS

top_node: Sort
join_methods_used: Hash Join, Nested Loop
scan_on_orders: Index Scan using idx_orders_order_date
scan_on_customers: Bitmap Heap Scan using idx_customers_county
estimated_vs_actual_rows_orders: 2072 vs 2061
planning_ms: 6.106
execution_ms: 10.990
result_rows: 91

Analysis:
PostgreSQL used the date and county indexes to filter the
relevant records. A Hash Join matched customers to orders,
while a Nested Loop used an index scan on order_items.

The estimated orders rows were close to actual rows,
indicating reasonably accurate planner estimates.
*/
-- Q22: List Existing Indexes in the SokoMart Schema
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'sokomart'
ORDER BY tablename, indexname;
/*
=========================================================
Q22: INDEX PERFORMANCE TESTING
=========================================================

(a) BEFORE INDEXES

Query                  Scan Type        Execution Time   Rows
Customer orders        Sequential Scan  8.796 ms         11
Payment lookup         Sequential Scan  22.241 ms        1
Product order items    Sequential Scan  28.138 ms        358

(b) AFTER INDEXES

Query                  Scan Type         Execution Time   Rows
Customer orders        Bitmap Heap Scan  0.148 ms         11
Payment lookup         Index Scan        0.128 ms         1
Product order items    Bitmap Heap Scan  0.770 ms         358

(c) PERFORMANCE IMPROVEMENT

Customer orders:       98.3%
Payment lookup:        99.4%
Product order items:   97.3%

All three queries showed substantial performance
improvements after restoring the supporting indexes.
*/
/*
Q22(c): PARTIAL INDEX ANALYSIS

Partial index: idx_orders_pending_date
Full index: idx_orders_order_date

Partial index size: 32 kB
Full index size: 1,112 kB

Storage reduction: approximately 97.1%

The partial index is significantly smaller because it
stores entries only for rows where order_status = 'pending'.

Note: The natural execution plan used idx_orders_status_date,
not idx_orders_pending_date. Therefore, partial index usage
was not demonstrated by that query.
*/
select * from products;
-- Q23(a): Record the original average Beauty product price
SELECT
    category,
    ROUND(AVG(price), 2) AS average_price
FROM sokomart.products
WHERE category = 'Beauty'
GROUP BY category;
-- Q23(a): Inspect Beauty product prices before the transaction
SELECT
    product_id,
    product_name,
    category,
    unit_price,
    cost_price
FROM sokomart.products
WHERE category = 'Beauty'
ORDER BY product_id
LIMIT 10;
-- Q23(a): Calculate the original average Beauty selling price
SELECT
    ROUND(AVG(unit_price), 2) AS original_average_unit_price
FROM sokomart.products
WHERE category = 'Beauty';
-- Q23(a): Test a 10% Beauty price reduction and roll it back
BEGIN;

UPDATE sokomart.products
SET unit_price = ROUND(unit_price * 0.90, 2)
WHERE category = 'Beauty';

-- Verify the temporary average price
SELECT
    ROUND(AVG(unit_price), 2) AS temporary_average_unit_price
FROM sokomart.products
WHERE category = 'Beauty';

ROLLBACK;

-- Confirm the original average price is restored
SELECT
    ROUND(AVG(unit_price), 2) AS restored_average_unit_price
FROM sokomart.products
WHERE category = 'Beauty';
-- Q23(a): Begin the temporary Beauty price reduction transaction
BEGIN;
-- Q23(a): Reduce Beauty selling prices by 10%
UPDATE sokomart.products
SET unit_price = ROUND(unit_price * 0.90, 2)
WHERE category = 'Beauty';
-- Q23(a): Verify temporary average Beauty selling price
SELECT
    ROUND(AVG(unit_price), 2) AS temporary_average_price
FROM sokomart.products
WHERE category = 'Beauty';
-- Q23(a): Roll back the temporary Beauty price reduction
ROLLBACK;
-- Q23(a): Confirm original Beauty average price is restored
SELECT
    ROUND(AVG(unit_price), 2) AS restored_average_price
FROM sokomart.products
WHERE category = 'Beauty';

/*
Q23(a): TRANSACTION AND ROLLBACK

Category: Beauty
Products affected: 45

Original average unit price: KSh 1,243.84
Temporary average after 10% reduction: KSh 1,119.46
Restored average after ROLLBACK: KSh 1,243.84

Conclusion:
The transaction successfully applied the temporary price
reduction. ROLLBACK restored all original selling prices.
*/
-- Q23(b): Check stock levels before restocking
SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166)
ORDER BY product_id;
-- Q23(b): Inspect audit log table structure
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'sokomart'
  AND table_name = 'audit_logs'
ORDER BY ordinal_position;
-- Q23(b): Restock product 59 and record the stock adjustment
BEGIN;

-- Capture the old stock and add 40 units
WITH stock_update AS (
    UPDATE sokomart.products
    SET stock_quantity = stock_quantity + 40
    WHERE product_id = 59
    RETURNING product_id, stock_quantity
)
INSERT INTO sokomart.audit_logs (
    table_name,
    record_id,
    action,
    old_data,
    new_data,
    changed_by,
    changed_at
)
SELECT
    'products',
    59,
    'RESTOCK',
    '{"stock_quantity": 1}'::jsonb,
    jsonb_build_object('stock_quantity', stock_quantity),
    CURRENT_USER,
    CURRENT_TIMESTAMP
FROM stock_update;
-- Q23(b): Inspect permitted audit action values
SELECT
    conname,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'sokomart.audit_logs'::regclass
  AND conname = 'chk_audit_action';
-- Q23(b): Clear the failed transaction
ROLLBACK;
-- Q23(b): Restock product 59 and record the stock adjustment
BEGIN;

UPDATE sokomart.products
SET stock_quantity = stock_quantity + 40
WHERE product_id = 59;

INSERT INTO sokomart.audit_logs (
    table_name,
    record_id,
    action,
    old_data,
    new_data,
    changed_by,
    changed_at
)
VALUES (
    'products',
    59,
    'UPDATE',
    '{"stock_quantity": 1}'::jsonb,
    '{"stock_quantity": 41}'::jsonb,
    CURRENT_USER,
    CURRENT_TIMESTAMP
);
-- Q23(b): Create a savepoint after restocking product 59
SAVEPOINT after_restock;
-- Q23(b): Simulate an incorrect stock update for product 166
UPDATE sokomart.products
SET stock_quantity = 0
WHERE product_id = 166;
-- Q23(b): Check stock quantities before rolling back to the savepoint
SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166)
ORDER BY product_id;
-- Q23(b): Undo the incorrect stock update for product 166
ROLLBACK TO SAVEPOINT after_restock;
-- Q23(b): Verify stock quantities after savepoint rollback
SELECT product_id, product_name, stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166)
ORDER BY product_id;
-- Q23(b): Restock product 59 and record the stock adjustment
UPDATE sokomart.products
SET stock_quantity = stock_quantity + 40
WHERE product_id = 59;

INSERT INTO sokomart.audit_logs (
    table_name, record_id, action,
    old_data, new_data, changed_by, changed_at
)
VALUES (
    'products', 59, 'UPDATE',
    '{"stock_quantity": 1}'::jsonb,
    '{"stock_quantity": 41}'::jsonb,
    CURRENT_USER, CURRENT_TIMESTAMP
);
-- Q23(b): Create savepoint after the successful restock
SAVEPOINT after_restock;
-- Q23(b): Simulate an incorrect stock update for product 166
UPDATE sokomart.products
SET stock_quantity = 0
WHERE product_id = 166;
-- Q23(b): Undo the incorrect update while preserving the restock
ROLLBACK TO SAVEPOINT after_restock;
-- Q23(b): Verify both stock quantities after rollback
SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166)
ORDER BY product_id;
-- Q23(b): Commit the successful stock adjustment
COMMIT;
-- Q23(b): Verify committed stock adjustments and audit record
SELECT product_id, product_name, stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166)
ORDER BY product_id;

SELECT audit_id, record_id, action, old_data, new_data, changed_by
FROM sokomart.audit_logs
WHERE table_name = 'products'
  AND record_id = 59
ORDER BY audit_id DESC
LIMIT 1;
/*
Q23(b): SAVEPOINT AND PARTIAL ROLLBACK

Product 59: Anker Power Bank 20000mAh
Original stock: 1
Restocked quantity: 40
Final stock: 41

Product 166: Maasai Leather Handbag Crossbody
Original stock: 1
Temporary incorrect stock: 0
Final stock after rollback: 1

Savepoint: after_restock
Action: ROLLBACK TO SAVEPOINT
Audit ID: 45
Audit action: UPDATE

Conclusion:
The savepoint preserved the successful restock of product 59
while allowing the incorrect stock update for product 166 to
be reversed. The transaction was successfully committed.
*/
-- Q23(c): Begin transaction for negative stock test
BEGIN;
-- Q23(c): Increase product 166 stock by 1
UPDATE sokomart.products
SET stock_quantity = stock_quantity + 1
WHERE product_id = 166;
-- Q23(c): Test the constraint by attempting negative stock
UPDATE sokomart.products
SET stock_quantity = -5
WHERE product_id = 166;
-- Q23(c): End the failed transaction
COMMIT;
-- Q23(c): Verify stock after the constraint violation
SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id = 166;
/*
Q23(c): CHECK CONSTRAINT AND TRANSACTION ROLLBACK

Product: 166 - Maasai Leather Handbag Crossbody

Initial stock: 1
Temporary stock after adding 1: 2
Attempted stock update: -5

Constraint violated: chk_products_stock
PostgreSQL error code: 23514

Final stock after transaction rollback: 1

Conclusion:
The database rejected negative stock due to the CHECK constraint.
The failed statement aborted the transaction, and COMMIT resulted
in a rollback. The original stock quantity remained unchanged.
*/

-- Q23(b): Investigate repeated restock operations
SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id = 59;

SELECT
    audit_id,
    record_id,
    action,
    old_data,
    new_data,
    changed_at
FROM sokomart.audit_logs
WHERE table_name = 'products'
  AND record_id = 59
ORDER BY audit_id;
-- Q23(b): Confirm current stock before reconciliation
SELECT product_id, product_name, stock_quantity
FROM sokomart.products
WHERE product_id = 59;
-- Q23(b): Reconcile product 59 stock to the intended final quantity
BEGIN;

UPDATE sokomart.products
SET stock_quantity = 41
WHERE product_id = 59
  AND stock_quantity = 81;

-- Verify the corrected quantity before committing
SELECT product_id, product_name, stock_quantity
FROM sokomart.products
WHERE product_id = 59;
-- Q23(b): Close the stock reconciliation transaction
COMMIT;

-- =========================================================
-- Q23(b): SAVEPOINT AND PARTIAL TRANSACTION ROLLBACK
-- =========================================================

BEGIN;

-- Step 1: Temporarily restore product 59 to its original
-- stock quantity so the restock demonstration starts at 1.
UPDATE sokomart.products
SET stock_quantity = 1
WHERE product_id = 59;

-- Step 2: Restock product 59 by 40 units.
UPDATE sokomart.products
SET stock_quantity = stock_quantity + 40
WHERE product_id = 59;

-- Step 3: Record the stock adjustment in the audit log.
INSERT INTO sokomart.audit_logs (
    table_name,
    record_id,
    action,
    old_data,
    new_data,
    changed_by,
    changed_at
)
VALUES (
    'products',
    59,
    'UPDATE',
    '{"stock_quantity": 1}'::jsonb,
    '{"stock_quantity": 41}'::jsonb,
    CURRENT_USER,
    CURRENT_TIMESTAMP
);

-- Step 4: Create a savepoint after the successful restock.
SAVEPOINT after_restock;

-- Step 5: Simulate a mistaken stock update for product 166.
UPDATE sokomart.products
SET stock_quantity = 0
WHERE product_id = 166;

-- Step 6: Inspect temporary stock quantities.
SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166)
ORDER BY product_id;

-- Step 7: Undo the incorrect update without undoing
-- the successful restock of product 59.
ROLLBACK TO SAVEPOINT after_restock;

-- Step 8: Commit the valid stock adjustment.
COMMIT;

-- Step 9: Verify final stock quantities.
SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166)
ORDER BY product_id;

-- Step 10: Verify the audit record created by this run.
SELECT
    audit_id,
    table_name,
    record_id,
    action,
    old_data,
    new_data,
    changed_by,
    changed_at
FROM sokomart.audit_logs
WHERE table_name = 'products'
  AND record_id = 59
ORDER BY audit_id DESC
LIMIT 1;

-- Check current stock before the savepoint demonstration
SELECT product_id, product_name, stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166)
ORDER BY product_id;	
-- Q23(b): Demonstrate SAVEPOINT and partial ROLLBACK

BEGIN;

-- Restore the starting stock quantities
UPDATE sokomart.products
SET stock_quantity = 1
WHERE product_id IN (59, 166);

-- Restock product 59 by 40 units
UPDATE sokomart.products
SET stock_quantity = stock_quantity + 40
WHERE product_id = 59;

-- Create savepoint after restocking
SAVEPOINT after_restock;

-- Intentionally set product 166 stock to zero
UPDATE sokomart.products
SET stock_quantity = 0
WHERE product_id = 166;

-- Show the temporary changes before rollback
SELECT product_id, product_name, stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166)
ORDER BY product_id;

-- Undo only the change made after the savepoint
ROLLBACK TO SAVEPOINT after_restock;

-- Show the final state before committing
SELECT product_id, product_name, stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166)
ORDER BY product_id;

COMMIT;
-- Verify committed stock quantities for Q23(b)
SELECT product_id, stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166)
ORDER BY product_id;
-- Restore the expected final stock quantities for Q23(b)
UPDATE sokomart.products
SET stock_quantity = CASE
    WHEN product_id = 59 THEN 41
    WHEN product_id = 166 THEN 1
END
WHERE product_id IN (59, 166)
RETURNING product_id, product_name, stock_quantity;
-- Q24(a): Analyse duplicate payment records in payment_staging

WITH duplicate_counts AS (
    SELECT
        payment_id,
        COUNT(*) AS copy_count
    FROM sokomart.payment_staging
    GROUP BY payment_id
)
SELECT
    COUNT(*) AS duplicated_payment_ids,
    COALESCE(SUM(copy_count - 1), 0) AS extra_duplicate_rows,
    COALESCE(MAX(copy_count), 0) AS maximum_copies
FROM duplicate_counts
WHERE copy_count > 1;
-- Q24(b): Identify the first 10 duplicate payment rows for deletion

WITH ranked_payments AS (
    SELECT
        staging_id,
        payment_id,
        order_id,
        payment_date,
        payment_method,
        amount,
        payment_status,
        transaction_reference,
        loaded_at,
        ROW_NUMBER() OVER (
            PARTITION BY payment_id
            ORDER BY loaded_at, staging_id
        ) AS copy_no
    FROM sokomart.payment_staging
)
SELECT *
FROM ranked_payments
WHERE copy_no > 1
ORDER BY payment_id, loaded_at, staging_id
LIMIT 10;
-- Q24(c): Record payment staging counts before deduplication

SELECT
    COUNT(*) AS total_staging_rows,
    COUNT(DISTINCT payment_id) AS distinct_payment_ids,
    COUNT(*) - COUNT(DISTINCT payment_id) AS extra_duplicate_rows
FROM sokomart.payment_staging;
-- Q24(c): Delete duplicate payment staging records

BEGIN;

WITH ranked_payments AS (
    SELECT
        staging_id,
        ROW_NUMBER() OVER (
            PARTITION BY payment_id
            ORDER BY loaded_at, staging_id
        ) AS copy_no
    FROM sokomart.payment_staging
)
DELETE FROM sokomart.payment_staging AS ps
USING ranked_payments AS rp
WHERE ps.staging_id = rp.staging_id
  AND rp.copy_no > 1;
-- Q24(c): Verify deduplication and compare payment totals

SELECT
    (SELECT COUNT(*) FROM sokomart.payment_staging) AS remaining_rows,
    (SELECT COUNT(DISTINCT payment_id)
     FROM sokomart.payment_staging) AS distinct_payment_ids,
    (SELECT SUM(amount)
     FROM sokomart.payment_staging) AS staging_total,
    (SELECT SUM(amount)
     FROM sokomart.payments) AS payments_total,
    (SELECT SUM(amount)
     FROM sokomart.payment_staging)
    =
    (SELECT SUM(amount)
     FROM sokomart.payments) AS totals_match;
-- Q24(c): Compare deduplicated staging payments with matching payments

SELECT
    COUNT(*) AS matched_payment_records,
    SUM(ps.amount) AS staging_total,
    SUM(p.amount) AS matching_payments_total,
    SUM(ps.amount) = SUM(p.amount) AS totals_match
FROM sokomart.payment_staging ps
JOIN sokomart.payments p
    ON p.payment_id = ps.payment_id;
-- Q24(c): Commit verified payment staging deduplication
COMMIT;
-- Q24(d): Create a unique index on payment_id

CREATE UNIQUE INDEX idx_payment_staging_payment_id
ON sokomart.payment_staging (payment_id);
-- Q24(d): Verify the unique index on payment_staging

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'sokomart'
  AND tablename = 'payment_staging'
  AND indexname = 'idx_payment_staging_payment_id';
-- Q24(d): Check all indexes on payment_staging

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'payment_staging'
ORDER BY schemaname, indexname;
-- Q24(d): Recreate the unique payment_id index if missing

CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_staging_payment_id
ON sokomart.payment_staging (payment_id);
-- Q24(d): Confirm the unique payment_id index exists

SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'sokomart'
  AND tablename = 'payment_staging';
-- Q24(d): Test rejection of a duplicate payment ID

INSERT INTO sokomart.payment_staging (
    payment_id,
    order_id,
    payment_date,
    payment_method,
    amount,
    payment_status,
    transaction_reference,
    loaded_at
)
SELECT
    payment_id,
    order_id,
    payment_date,
    payment_method,
    amount,
    payment_status,
    transaction_reference,
    CURRENT_TIMESTAMP
FROM sokomart.payment_staging
ORDER BY payment_id
LIMIT 1;
-- Q24(d): Clear the failed duplicate-insert transaction
ROLLBACK;
-- Q24(d): Test rejection of duplicate payment_id with all required columns

INSERT INTO sokomart.payment_staging (
    payment_id,
    order_id,
    payment_date,
    payment_method,
    amount,
    payment_status,
    transaction_reference,
    source_file,
    loaded_at
)
SELECT
    payment_id,
    order_id,
    payment_date,
    payment_method,
    amount,
    payment_status,
    transaction_reference,
    source_file,
    CURRENT_TIMESTAMP
FROM sokomart.payment_staging
ORDER BY payment_id
LIMIT 1;
-- Q24(d): Check whether duplicate payment IDs exist

SELECT
    payment_id,
    COUNT(*) AS copy_count
FROM sokomart.payment_staging
GROUP BY payment_id
HAVING COUNT(*) > 1;
-- Q24(d): Inspect the duplicate payment_id records

SELECT
    staging_id,
    payment_id,
    order_id,
    source_file,
    loaded_at
FROM sokomart.payment_staging
WHERE payment_id = 5
ORDER BY loaded_at, staging_id;
-- Q24(d): Check unique index validity

SELECT
    indexrelid::regclass AS index_name,
    indisunique,
    indisvalid,
    indisready
FROM pg_index
WHERE indexrelid =
    'sokomart.idx_payment_staging_payment_id'::regclass;
-- Q24(d): Remove the test duplicate inserted during constraint testing

DELETE FROM sokomart.payment_staging
WHERE staging_id = 2642
  AND payment_id = 5;
-- Q24(d): Verify payment_id 5 has only its original record

SELECT staging_id, payment_id, loaded_at
FROM sokomart.payment_staging
WHERE payment_id = 5;
-- Q24(d): Create the permanent unique index on payment_id

CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_staging_payment_id
ON sokomart.payment_staging (payment_id);
-- Q24(d): Verify the permanent unique index

SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'sokomart'
  AND tablename = 'payment_staging'
  AND indexname = 'idx_payment_staging_payment_id';
-- Q24(d): Test rejection of a duplicate payment ID

INSERT INTO sokomart.payment_staging (
    payment_id,
    order_id,
    payment_date,
    payment_method,
    amount,
    payment_status,
    transaction_reference,
    source_file,
    loaded_at
)
SELECT
    payment_id,
    order_id,
    payment_date,
    payment_method,
    amount,
    payment_status,
    transaction_reference,
    source_file,
    CURRENT_TIMESTAMP
FROM sokomart.payment_staging
WHERE payment_id = 5
LIMIT 1;
-- Q24: Final verification of payment staging uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT payment_id) AS distinct_payment_ids
FROM sokomart.payment_staging;