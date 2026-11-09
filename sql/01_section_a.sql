-- Q1: Big Spenders of 2025
-- Find customers whose completed-order spending was above
-- the average spending of customers who bought in 2025.

WITH customer_spending AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS full_name,
        c.county,
        SUM(oi.line_total) AS total_spent_2025
    FROM sokomart.customers c
    JOIN sokomart.orders o
        ON c.customer_id = o.customer_id
    JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
      AND o.order_date >= '2025-01-01'
      AND o.order_date < '2026-01-01'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.county
),
average_spending AS (
    SELECT AVG(total_spent_2025) AS avg_spent_2025
    FROM customer_spending
)
SELECT
    cs.customer_id,
    cs.full_name,
    cs.county,
    cs.total_spent_2025,
    ROUND(a.avg_spent_2025, 2) AS avg_spent_2025,
    ROUND(cs.total_spent_2025 - a.avg_spent_2025, 2) AS amount_above_avg
FROM customer_spending cs
CROSS JOIN average_spending a
WHERE cs.total_spent_2025 > a.avg_spent_2025
ORDER BY cs.total_spent_2025 DESC; 
WITH customer_spending AS (
    SELECT
        o.customer_id,
        SUM(oi.line_total) AS total_spent_2025
    FROM sokomart.orders o
    JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
      AND o.order_date >= '2025-01-01'
      AND o.order_date < '2026-01-01'
    GROUP BY o.customer_id
),
average_spending AS (
    SELECT AVG(total_spent_2025) AS avg_spent_2025
    FROM customer_spending
)
SELECT
    COUNT(*) AS customers_who_bought,
    ROUND(MAX(avg_spent_2025), 2) AS avg_spent_2025,
    COUNT(*) FILTER (
        WHERE total_spent_2025 > avg_spent_2025
    ) AS customers_above_average
FROM customer_spending
CROSS JOIN average_spending;
-- Q2: Premium Products

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    (
        SELECT AVG(p2.unit_price)
        FROM sokomart.products p2
        WHERE p2.category = p.category
    ) AS category_avg_price,
    ROUND(
        p.unit_price - (
            SELECT AVG(p2.unit_price)
            FROM sokomart.products p2
            WHERE p2.category = p.category
        ),
        2
    ) AS price_gap
FROM sokomart.products p
WHERE p.product_status = 'active'
  AND p.unit_price > (
      SELECT AVG(p2.unit_price)
      FROM sokomart.products p2
      WHERE p2.category = p.category
  )
ORDER BY p.category, price_gap DESC;
SELECT
    p.category,
    COUNT(*) AS premium_products
FROM sokomart.products p
WHERE p.product_status = 'active'
  AND p.unit_price > (
      SELECT AVG(p2.unit_price)
      FROM sokomart.products p2
      WHERE p2.category = p.category
  )
GROUP BY p.category
ORDER BY p.category;
-- Q3: Monthly P&L for January to October 2026

WITH completed_order_lines AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::date AS month,
        oi.line_total AS revenue,
        oi.quantity * p.cost_price AS cost
    FROM sokomart.orders o
    JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    JOIN sokomart.products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'completed'
      AND o.order_date >= '2026-01-01'
      AND o.order_date < '2026-11-01'
),
monthly_totals AS (
    SELECT
        month,
        SUM(revenue) AS revenue,
        SUM(cost) AS cost
    FROM completed_order_lines
    GROUP BY month
),
monthly_profit AS (
    SELECT
        month,
        revenue,
        cost,
        revenue - cost AS gross_profit
    FROM monthly_totals
)
SELECT
    TO_CHAR(month, 'YYYY-MM') AS month,
    revenue,
    cost,
    gross_profit,
    ROUND(
        100.0 * gross_profit / NULLIF(revenue, 0),
        2
    ) AS margin_pct
FROM monthly_profit
ORDER BY month;
-- Q4: Nakuru Cross-Category Shoppers

SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    c.county,
    shopper_summary.category_count,
    shopper_summary.total_spent
FROM sokomart.customers c
JOIN (
    SELECT
        o.customer_id,
        COUNT(DISTINCT p.category) AS category_count,
        SUM(oi.line_total) AS total_spent
    FROM sokomart.orders o
    JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    JOIN sokomart.products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'completed'
    GROUP BY o.customer_id
) AS shopper_summary
    ON c.customer_id = shopper_summary.customer_id
WHERE c.county = 'Nakuru'
  AND shopper_summary.category_count >= 3
ORDER BY
    shopper_summary.category_count DESC,
    shopper_summary.total_spent DESC;
-- Q4 Summary: Qualifying customers and those who bought all five categories

SELECT
    COUNT(*) AS qualifying_customers,
    COUNT(*) FILTER (
        WHERE category_count = 5
    ) AS customers_who_bought_all_five_categories
FROM (
    SELECT
        o.customer_id,
        COUNT(DISTINCT p.category) AS category_count
    FROM sokomart.orders o
    JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    JOIN sokomart.products p
        ON oi.product_id = p.product_id
    JOIN sokomart.customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'completed'
      AND c.county = 'Nakuru'
    GROUP BY o.customer_id
    HAVING COUNT(DISTINCT p.category) >= 3
) AS qualifying_shoppers;
-- Q5: Products Never Ordered

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.product_status,
    p.stock_quantity,
    p.created_at
FROM sokomart.products p
WHERE NOT EXISTS (
    SELECT 1
    FROM sokomart.order_items oi
    WHERE oi.product_id = p.product_id
)
ORDER BY
    p.category,
    p.product_name;