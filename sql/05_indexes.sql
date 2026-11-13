-- SokoMart: Supporting Indexes
-- Q22: Index Performance Testing

-- Customer lookup and date filtering
CREATE INDEX IF NOT EXISTS idx_orders_customer_date
ON sokomart.orders (customer_id, order_date);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id
ON sokomart.orders (customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_order_date
ON sokomart.orders (order_date);

CREATE INDEX IF NOT EXISTS idx_orders_status_date
ON sokomart.orders (order_status, order_date);


-- Payment lookup
CREATE INDEX IF NOT EXISTS idx_payments_order_id
ON sokomart.payments (order_id);

-- Product lookup in order items
CREATE INDEX IF NOT EXISTS idx_order_items_product_id
ON sokomart.order_items (product_id);

-- Customer county filtering
CREATE INDEX IF NOT EXISTS idx_customers_county
ON sokomart.customers (county);

-- Q22(a): Temporary index removal for baseline testing
-- Run this block only when instructed.

-- DROP INDEX IF EXISTS sokomart.idx_orders_customer_date;
-- DROP INDEX IF EXISTS sokomart.idx_orders_customer_id;
-- DROP INDEX IF EXISTS sokomart.idx_orders_order_date;
-- DROP INDEX IF EXISTS sokomart.idx_orders_status_date;
-- DROP INDEX IF EXISTS sokomart.idx_payments_order_id;
-- DROP INDEX IF EXISTS sokomart.idx_order_items_product_id;
-- Q22(a): Drop selected indexes for baseline performance testing
DROP INDEX IF EXISTS sokomart.idx_orders_customer_date;
DROP INDEX IF EXISTS sokomart.idx_orders_customer_id;
DROP INDEX IF EXISTS sokomart.idx_orders_order_date;
DROP INDEX IF EXISTS sokomart.idx_orders_status_date;
DROP INDEX IF EXISTS sokomart.idx_payments_order_id;
DROP INDEX IF EXISTS sokomart.idx_order_items_product_id;

-- Refresh table statistics after index removal
ANALYZE sokomart.orders;
ANALYZE sokomart.payments;
ANALYZE sokomart.order_items;
-- Q22(a): Baseline execution plan for customer order lookup
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    order_date,
    total_amount
FROM sokomart.orders
WHERE customer_id = 408
ORDER BY order_date;
-- Q22(a): Baseline execution plan for payment lookup
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM sokomart.payments
WHERE order_id = 25000;
-- Q22(a): Baseline execution plan for product order-item lookup
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    quantity,
    line_total
FROM sokomart.order_items
WHERE product_id = 71;
-- Q22(b): Restore indexes for after-index performance testing
CREATE INDEX IF NOT EXISTS idx_orders_customer_date
ON sokomart.orders (customer_id, order_date);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id
ON sokomart.orders (customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_order_date
ON sokomart.orders (order_date);

CREATE INDEX IF NOT EXISTS idx_orders_status_date
ON sokomart.orders (order_status, order_date);

CREATE INDEX IF NOT EXISTS idx_payments_order_id
ON sokomart.payments (order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id
ON sokomart.order_items (product_id);

-- Refresh statistics after index creation
ANALYZE sokomart.orders;
ANALYZE sokomart.payments;
ANALYZE sokomart.order_items;

-- Q22(b): After-index execution plan for customer order lookup
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    order_date,
    total_amount
FROM sokomart.orders
WHERE customer_id = 408
ORDER BY order_date;
-- Q22(b): After-index execution plan for payment lookup
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM sokomart.payments
WHERE order_id = 25000;
-- Q22(b): After-index execution plan for product order-item lookup
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    quantity,
    line_total
FROM sokomart.order_items
WHERE product_id = 71;
-- Q22(c): Create a partial index for pending orders by date
CREATE INDEX IF NOT EXISTS idx_orders_pending_date
ON sokomart.orders (order_date)
WHERE order_status = 'pending';

ANALYZE sokomart.orders;
-- Q22(c): Verify partial index usage for pending orders
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    order_date,
    total_amount
FROM sokomart.orders
WHERE order_status = 'pending'
  AND order_date < DATE '2026-10-25';
-- Q22(c): Compare partial and full order-date index sizes
SELECT
    'idx_orders_pending_date' AS index_name,
    pg_size_pretty(
        pg_relation_size('sokomart.idx_orders_pending_date')
    ) AS index_size

UNION ALL

SELECT
    'idx_orders_order_date',
    pg_size_pretty(
        pg_relation_size('sokomart.idx_orders_order_date')
    );
-- Q22(c): Retrieve partial and full index sizes
SELECT
    pg_size_pretty(pg_relation_size('sokomart.idx_orders_pending_date'))
        AS partial_index_size,
    pg_size_pretty(pg_relation_size('sokomart.idx_orders_order_date'))
        AS full_index_size;
-- Q22(c): Verify whether the partial index exists
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'sokomart'
  AND indexname IN (
      'idx_orders_pending_date',
      'idx_orders_order_date'
  );
-- Q22(c): Recreate the pending-orders partial index
CREATE INDEX idx_orders_pending_date
ON sokomart.orders (order_date)
WHERE order_status = 'pending';
-- Q22(c): Confirm partial index creation
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'sokomart'
  AND indexname = 'idx_orders_pending_date';
-- Q22(c): Compare partial and full order-date index sizes
SELECT
    pg_size_pretty(
        pg_relation_size('sokomart.idx_orders_pending_date')
    ) AS partial_index_size,
    pg_size_pretty(
        pg_relation_size('sokomart.idx_orders_order_date')
    ) AS full_index_size;