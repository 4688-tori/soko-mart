-- =====================================================
-- SOKOMART KENYA - ADVANCED SQL PRACTICAL PROJECT
-- DAY 2: SECTION B - WINDOW FUNCTIONS
-- Questions 6-10
-- =====================================================

-- Q6: County Leaderboards
-- Top 3 customers by lifetime completed-order revenue in each county

WITH customer_revenue AS (
    SELECT
        c.county,
        c.customer_id,
        c.first_name || ' ' || c.last_name AS full_name,
        COALESCE(SUM(oi.line_total), 0::NUMERIC) AS total_spent
    FROM sokomart.customers c
    LEFT JOIN sokomart.orders o
        ON c.customer_id = o.customer_id
       AND o.order_status = 'completed'
    LEFT JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        c.county,
        c.customer_id,
        c.first_name,
        c.last_name
),
ranked_customers AS (
    SELECT
        county,
        customer_id,
        full_name,
        total_spent,
        DENSE_RANK() OVER (
            PARTITION BY county
            ORDER BY total_spent DESC
        ) AS county_rank
    FROM customer_revenue
)
SELECT
    county,
    county_rank,
    customer_id,
    full_name,
    total_spent
FROM ranked_customers
WHERE county_rank <= 3
ORDER BY
    county,
    county_rank,
    customer_id;

-- =====================================================
-- Q7: Best Sellers per Category, 2025
-- Top 3 products in each category by revenue
-- =====================================================

WITH product_sales AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(oi.line_total) AS revenue,
        SUM(oi.quantity) AS units_sold
    FROM sokomart.products p
    JOIN sokomart.order_items oi
        ON p.product_id = oi.product_id
    JOIN sokomart.orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'completed'
      AND o.order_date >= '2025-01-01'
      AND o.order_date < '2026-01-01'
    GROUP BY
        p.category,
        p.product_id,
        p.product_name
),
ranked_products AS (
    SELECT
        category,
        product_id,
        product_name,
        revenue,
        units_sold,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY revenue DESC, product_id
        ) AS rank_in_category
    FROM product_sales
)
SELECT
    category,
    rank_in_category,
    product_id,
    product_name,
    revenue,
    units_sold
FROM ranked_products
WHERE rank_in_category <= 3
ORDER BY
    category,
    rank_in_category;

-- =====================================================
-- Q8: Month-over-Month Revenue Growth
-- January 2025 to October 2026
-- =====================================================

WITH calendar_months AS (
    SELECT
        GENERATE_SERIES(
            '2025-01-01'::DATE,
            '2026-10-01'::DATE,
            INTERVAL '1 month'
        )::DATE AS month_date
),
monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::DATE AS month_date,
        SUM(oi.line_total) AS revenue
    FROM sokomart.orders o
    JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
      AND o.order_date >= '2025-01-01'
      AND o.order_date < '2026-11-01'
    GROUP BY DATE_TRUNC('month', o.order_date)::DATE
),
monthly_revenue AS (
    SELECT
        cm.month_date,
        COALESCE(ms.revenue, 0::NUMERIC) AS revenue
    FROM calendar_months cm
    LEFT JOIN monthly_sales ms
        ON cm.month_date = ms.month_date
),
revenue_with_previous AS (
    SELECT
        month_date,
        revenue,
        LAG(revenue) OVER (
            ORDER BY month_date
        ) AS prev_month_revenue
    FROM monthly_revenue
)
SELECT
    TO_CHAR(month_date, 'YYYY-MM') AS month,
    revenue,
    prev_month_revenue,
    ROUND(
        100.0 * (revenue - prev_month_revenue)
        / NULLIF(prev_month_revenue, 0),
        2
    ) AS growth_pct
FROM revenue_with_previous
ORDER BY month_date;

-- =====================================================
-- Q9: Is Each Order Bigger Than the Last?
-- Nyeri customers, completed orders in 2026
-- =====================================================

WITH order_comparisons AS (
    SELECT
        c.customer_id,
        o.order_id,
        o.order_date,
        o.total_amount,
        LAG(o.total_amount) OVER (
            PARTITION BY c.customer_id
            ORDER BY o.order_date, o.order_id
        ) AS previous_order_amount
    FROM sokomart.customers c
    JOIN sokomart.orders o
        ON c.customer_id = o.customer_id
    WHERE c.county = 'Nyeri'
      AND o.order_status = 'completed'
      AND o.order_date >= '2026-01-01'
      AND o.order_date < '2027-01-01'
)
SELECT
    customer_id,
    order_id,
    order_date,
    total_amount,
    previous_order_amount,
    total_amount - previous_order_amount AS change_amount,
    CASE
        WHEN previous_order_amount IS NULL THEN 'first order'
        WHEN total_amount > previous_order_amount THEN 'up'
        WHEN total_amount < previous_order_amount THEN 'down'
        ELSE 'same'
    END AS direction
FROM order_comparisons
ORDER BY
    customer_id,
    order_date,
    order_id;


-- Q9 SUMMARY: Order comparison statistics

WITH order_comparisons AS (
    SELECT
        c.customer_id,
        o.total_amount,
        LAG(o.total_amount) OVER (
            PARTITION BY c.customer_id
            ORDER BY o.order_date, o.order_id
        ) AS previous_order_amount
    FROM sokomart.customers c
    JOIN sokomart.orders o
        ON c.customer_id = o.customer_id
    WHERE c.county = 'Nyeri'
      AND o.order_status = 'completed'
      AND o.order_date >= '2026-01-01'
      AND o.order_date < '2027-01-01'
)
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    COUNT(*) FILTER (
        WHERE previous_order_amount IS NULL
    ) AS first_orders,
    COUNT(*) FILTER (
        WHERE total_amount > previous_order_amount
    ) AS orders_bigger_than_previous,
    COUNT(*) FILTER (
        WHERE total_amount < previous_order_amount
    ) AS orders_smaller_than_previous
FROM order_comparisons;
-- =====================================================
-- Q10: Year-to-Date Revenue
-- Monthly revenue, YTD running total and all-time total
-- =====================================================

WITH calendar_months AS (
    SELECT
        GENERATE_SERIES(
            '2025-01-01'::DATE,
            '2026-10-01'::DATE,
            INTERVAL '1 month'
        )::DATE AS month_date
),
monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::DATE AS month_date,
        SUM(oi.line_total) AS monthly_revenue
    FROM sokomart.orders o
    JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
      AND o.order_date >= '2025-01-01'
      AND o.order_date < '2026-11-01'
    GROUP BY DATE_TRUNC('month', o.order_date)::DATE
),
monthly_totals AS (
    SELECT
        EXTRACT(YEAR FROM cm.month_date)::INTEGER AS year,
        TO_CHAR(cm.month_date, 'YYYY-MM') AS month,
        cm.month_date,
        COALESCE(ms.monthly_revenue, 0::NUMERIC) AS monthly_revenue
    FROM calendar_months cm
    LEFT JOIN monthly_sales ms
        ON cm.month_date = ms.month_date
)
SELECT
    year,
    month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        PARTITION BY year
        ORDER BY month_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_revenue_ytd,
    SUM(monthly_revenue) OVER (
        ORDER BY month_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_revenue_all_time
FROM monthly_totals
ORDER BY month_date;

