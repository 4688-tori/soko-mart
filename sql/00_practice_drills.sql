SELECT
    current_database() AS database_name,
    current_schema() AS current_schema;
SET search_path TO sokomart;
--D1
SELECT
    product_id,
    product_name,
    category,
    unit_price,
    (SELECT AVG(unit_price)
     FROM sokomart.products) AS overall_avg_price
FROM sokomart.products
WHERE unit_price > (
    SELECT AVG(unit_price)
    FROM sokomart.products
)
ORDER BY unit_price DESC
LIMIT 10;
--D2
SELECT
    COUNT(*) AS products_above_average
FROM sokomart.products
WHERE unit_price > (
    SELECT AVG(unit_price)
    FROM sokomart.products
);
--D2,CUSTOMERS LIVING IN MOMBASA
SELECT
    customer_id,
    first_name,
    last_name,
    email
FROM sokomart.customers
WHERE county = 'Mombasa'
AND customer_id IN (
    SELECT customer_id
    FROM sokomart.orders
    WHERE order_date >= '2025-12-01'
      AND order_date < '2026-01-01'
)
ORDER BY customer_id;
--QUALYFYING CUSTOMER
SELECT
    COUNT(*) AS mombasa_customers_with_december_orders
FROM sokomart.customers
WHERE county = 'Mombasa'
AND customer_id IN (
    SELECT customer_id
    FROM sokomart.orders
    WHERE order_date >= '2025-12-01'
      AND order_date < '2026-01-01'
);
--D3Kisumu customers who falied payment
SELECT
    COUNT(*) AS kisumu_customers_with_failed_payment
FROM sokomart.customers c
WHERE c.county = 'Kisumu'
AND EXISTS (
    SELECT 1
    FROM sokomart.orders o
    JOIN sokomart.payments p
        ON o.order_id = p.order_id
    WHERE o.customer_id = c.customer_id
      AND p.payment_status = 'failed'
);
--D4order statistic by status
SELECT
    order_status,
    COUNT(*) AS orders,
    ROUND(AVG(lines_per_order), 2) AS avg_lines_per_order,
    ROUND(AVG(units_per_order), 2) AS avg_units_per_order
FROM (
    SELECT
        o.order_id,
        o.order_status,
        COUNT(oi.order_item_id) AS lines_per_order,
        SUM(oi.quantity) AS units_per_order
    FROM sokomart.orders o
    JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.order_status
) AS order_stats
GROUP BY order_status
ORDER BY order_status;
--D5 — Top 5 shipping counties by completed orders in 2026
WITH completed_2026 AS (
    SELECT
        shipping_county
    FROM sokomart.orders
    WHERE order_status = 'completed'
      AND order_date >= '2026-01-01'
      AND order_date < '2027-01-01'
)
SELECT
    shipping_county,
    COUNT(*) AS completed_orders
FROM completed_2026
GROUP BY shipping_county
ORDER BY completed_orders DESC
LIMIT 5;
--D6 — 2025 monthly completed orders vs average
WITH monthly_counts AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month,
        COUNT(*) AS completed_orders
    FROM sokomart.orders
    WHERE order_status = 'completed'
      AND order_date >= '2025-01-01'
      AND order_date < '2026-01-01'
    GROUP BY DATE_TRUNC('month', order_date)
),
monthly_stats AS (
    SELECT
        AVG(completed_orders) AS avg_per_month
    FROM monthly_counts
)
SELECT
    TO_CHAR(mc.month, 'YYYY-MM') AS month,
    mc.completed_orders,
    ROUND(ms.avg_per_month, 2) AS avg_per_month,
    CASE
        WHEN mc.completed_orders > ms.avg_per_month
            THEN 'above average'
        ELSE 'at/below average'
    END AS vs_average
FROM monthly_counts mc
CROSS JOIN monthly_stats ms
ORDER BY mc.month;
--D7 — Customer order count function
CREATE OR REPLACE FUNCTION sokomart.fn_order_count(
    p_customer_id INTEGER
)
RETURNS INTEGER
LANGUAGE SQL
AS $$
    SELECT COUNT(*)::INTEGER
    FROM sokomart.orders
    WHERE customer_id = p_customer_id;
$$;
SELECT
    sokomart.fn_order_count(177) AS customer_177_orders;

SELECT
    sokomart.fn_order_count(-1) AS nonexistent_customer_orders;
--D8 — Customer status stored procedure
CREATE OR REPLACE PROCEDURE sokomart.sp_set_customer_status(
    p_customer_id INTEGER,
    p_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_status NOT IN ('active', 'inactive', 'suspended') THEN
        RAISE EXCEPTION 'Invalid customer status: %', p_status;
    END IF;

    UPDATE sokomart.customers
    SET customer_status = p_status
    WHERE customer_id = p_customer_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer ID % does not exist', p_customer_id;
    END IF;
END;
$$;
BEGIN;

CALL sokomart.sp_set_customer_status(177, 'suspended');

SELECT
    customer_id,
    customer_status
FROM sokomart.customers
WHERE customer_id = 177;

ROLLBACK;
SELECT
    customer_id,
    customer_status
FROM sokomart.customers
WHERE customer_id = 177;
CALL sokomart.sp_set_customer_status(177, 'vip');
--D9 — Beauty products below average stock
WITH beauty_products AS (
    SELECT
        product_id,
        product_name,
        stock_quantity
    FROM sokomart.products
    WHERE category = 'Beauty'
)
SELECT
    product_id,
    product_name,
    stock_quantity,
    (
        SELECT AVG(stock_quantity)
        FROM beauty_products
    ) AS beauty_avg_stock
FROM beauty_products
WHERE stock_quantity < (
    SELECT AVG(stock_quantity)
    FROM beauty_products
)
ORDER BY stock_quantity ASC;
--D10 — County customer and revenue summary
CREATE OR REPLACE PROCEDURE sokomart.sp_county_summary(
    IN p_county VARCHAR,
    OUT p_customers INTEGER,
    OUT p_revenue NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COUNT(*)::INTEGER
    INTO p_customers
    FROM sokomart.customers
    WHERE county = p_county;

    SELECT COALESCE(SUM(oi.line_total), 0)
    INTO p_revenue
    FROM sokomart.orders o
    JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    JOIN sokomart.customers c
        ON o.customer_id = c.customer_id
    WHERE c.county = p_county
      AND o.order_status = 'completed';
END;
$$;CALL sokomart.sp_county_summary('Nakuru', NULL, NULL);
