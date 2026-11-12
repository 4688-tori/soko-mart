
-- ============================================================
-- LUXDEVHQ COHORT 9: SOKOMART KENYA
-- SECTION D: VIEWS, MATERIALIZED VIEWS, FUNCTIONS,
--            PROCEDURES AND TRIGGERS
-- Questions 16–19
-- Schema: sokomart
-- ============================================================


-- ============================================================
-- Q16(a): CUSTOMER PURCHASE SUMMARY VIEW
-- Create a view showing completed-order purchase behaviour
-- for all customers, including customers with no completed orders.
-- ============================================================

CREATE OR REPLACE VIEW sokomart.v_customer_purchase_summary AS
WITH completed_order_totals AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.line_total) AS order_total
    FROM sokomart.orders AS o
    JOIN sokomart.order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
    GROUP BY
        o.order_id,
        o.customer_id,
        o.order_date
),
customer_summary AS (
    SELECT
        customer_id,
        COUNT(order_id) AS completed_orders,
        SUM(order_total) AS lifetime_spent,
        AVG(order_total) AS average_order_value,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM completed_order_totals
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.county,
    COALESCE(cs.completed_orders, 0) AS completed_orders,
    COALESCE(cs.lifetime_spent, 0) AS lifetime_spent,
    COALESCE(cs.average_order_value, 0) AS average_order_value,
    cs.first_order_date,
    cs.last_order_date,
    CASE
        WHEN cs.last_order_date IS NULL THEN NULL
        ELSE DATE '2026-10-31' - cs.last_order_date::date
    END AS days_since_last_order
FROM sokomart.customers AS c
LEFT JOIN customer_summary AS cs
    ON c.customer_id = cs.customer_id;


-- ============================================================
-- Q16(a): VERIFY CUSTOMER PURCHASE SUMMARY
-- Display the top 10 Kiambu customers by lifetime spending.
-- ============================================================

SELECT *
FROM sokomart.v_customer_purchase_summary
WHERE county = 'Kiambu'
ORDER BY lifetime_spent DESC
LIMIT 10;


-- ============================================================
-- Q16(a): VALIDATE CUSTOMER COUNTS
-- ============================================================

SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE completed_orders = 0)
        AS customers_with_zero_completed_orders
FROM sokomart.v_customer_purchase_summary;


-- ============================================================
-- Q16(b): MONTHLY CATEGORY SALES MATERIALIZED VIEW
-- Include completed-order revenue and gross profit.
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS
sokomart.mv_monthly_category_sales AS
SELECT
    DATE_TRUNC('month', o.order_date)::date AS sales_month,
    p.category,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.line_total) AS revenue,
    SUM(oi.line_total - (oi.quantity * p.cost_price))
        AS gross_profit
FROM sokomart.orders AS o
JOIN sokomart.order_items AS oi
    ON o.order_id = oi.order_id
JOIN sokomart.products AS p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'completed'
GROUP BY
    DATE_TRUNC('month', o.order_date)::date,
    p.category;


-- ============================================================
-- Q16(b): CREATE UNIQUE INDEX ON MATERIALIZED VIEW
-- Required for concurrent refresh.
-- ============================================================

CREATE UNIQUE INDEX IF NOT EXISTS
idx_mv_monthly_category_sales_unique
ON sokomart.mv_monthly_category_sales (sales_month, category);


-- ============================================================
-- Q16(b): VERIFY DECEMBER 2025 CATEGORY SALES
-- ============================================================

SELECT
    sales_month,
    category,
    orders,
    units_sold,
    revenue,
    gross_profit
FROM sokomart.mv_monthly_category_sales
WHERE sales_month = DATE '2025-12-01'
ORDER BY revenue DESC;



-- ============================================================
-- Q17: CUSTOMER SPEND FUNCTION
-- Calculate completed-order revenue for a customer
-- between the supplied start and end dates.
-- ============================================================

CREATE OR REPLACE FUNCTION sokomart.fn_customer_spend(
    p_customer_id INTEGER,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_spend NUMERIC;
BEGIN
    IF p_end_date < p_start_date THEN
        RAISE EXCEPTION
            'End date cannot be earlier than start date';
    END IF;

    SELECT COALESCE(SUM(oi.line_total), 0)
    INTO v_total_spend
    FROM sokomart.orders AS o
    JOIN sokomart.order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.customer_id = p_customer_id
      AND o.order_status = 'completed'
      AND o.order_date >= p_start_date
      AND o.order_date < p_end_date + INTERVAL '1 day';

    RETURN COALESCE(v_total_spend, 0);
END;
$$;


-- ============================================================
-- Q17: TEST CUSTOMER SPEND FUNCTION
-- Customer 4000: 2025 spending.
-- ============================================================

SELECT
    sokomart.fn_customer_spend(
        4000,
        DATE '2025-01-01',
        DATE '2025-12-31'
    ) AS spend_2025;


-- ============================================================
-- Q17: TEST CUSTOMER SPEND FUNCTION
-- Customer 4000: January to October 2026.
-- ============================================================

SELECT
    sokomart.fn_customer_spend(
        4000,
        DATE '2026-01-01',
        DATE '2026-10-31'
    ) AS spend_jan_oct_2026;


-- ============================================================
-- Q17: TEST CUSTOMER SPEND FUNCTION
-- Customer 4000: full requested reporting period.
-- ============================================================

SELECT
    sokomart.fn_customer_spend(
        4000,
        DATE '2025-01-01',
        DATE '2026-10-31'
    ) AS total_spend;


-- ============================================================
-- Q17: TEST CUSTOMER SPEND FUNCTION
-- Customer 4000: December 2025.
-- ============================================================

SELECT
    sokomart.fn_customer_spend(
        4000,
        DATE '2025-12-01',
        DATE '2025-12-31'
    ) AS december_2025_spend;


-- ============================================================
-- Q17: TEST NONEXISTENT CUSTOMER
-- Expected result: 0.
-- ============================================================

SELECT
    sokomart.fn_customer_spend(
        -1,
        DATE '2025-01-01',
        DATE '2025-12-31'
    ) AS nonexistent_customer_spend;


-- ============================================================
-- Q17: COMPARE FUNCTION WITH CUSTOMER SUMMARY VIEW
-- ============================================================

SELECT
    customer_id,
    lifetime_spent,
    sokomart.fn_customer_spend(
        customer_id,
        DATE '2025-01-01',
        DATE '2026-10-31'
    ) AS function_spend
FROM sokomart.v_customer_purchase_summary
WHERE customer_id = 4000;



-- ============================================================
-- Q17: TOP 5 NAIROBI CUSTOMERS
-- Rank customers by December 2025 completed-order spend.
-- ============================================================

SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    SUM(oi.line_total) AS december_spend
FROM sokomart.customers AS c
JOIN sokomart.orders AS o
    ON c.customer_id = o.customer_id
JOIN sokomart.order_items AS oi
    ON o.order_id = oi.order_id
WHERE c.county = 'Nairobi'
  AND o.order_status = 'completed'
  AND o.order_date >= TIMESTAMP '2025-12-01'
  AND o.order_date < TIMESTAMP '2026-01-01'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY december_spend DESC
LIMIT 5;


-- ============================================================
-- Q18: PRODUCT PRICE UPDATE PROCEDURE
-- Update a product's selling price, record price history,
-- and write an audit log. Reject prices below cost.
-- ============================================================

CREATE OR REPLACE PROCEDURE sokomart.sp_update_product_price(
    p_product_id INTEGER,
    p_new_price NUMERIC,
    p_reason VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_price NUMERIC;
    v_cost_price NUMERIC;
BEGIN
    SELECT
        unit_price,
        cost_price
    INTO
        v_old_price,
        v_cost_price
    FROM sokomart.products
    WHERE product_id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Product ID % does not exist',
            p_product_id;
    END IF;

    IF p_new_price <= 0 THEN
        RAISE EXCEPTION
            'New price must be greater than zero';
    END IF;

    IF p_new_price < v_cost_price THEN
        RAISE EXCEPTION
            'New price (%) cannot be below cost price (%)',
            p_new_price,
            v_cost_price;
    END IF;

    UPDATE sokomart.products
    SET unit_price = p_new_price
    WHERE product_id = p_product_id;

    INSERT INTO sokomart.product_price_history (
        product_id,
        old_price,
        new_price,
        change_reason,
        changed_by,
        changed_at
    )
    VALUES (
        p_product_id,
        v_old_price,
        p_new_price,
        p_reason,
        CURRENT_USER,
        CURRENT_TIMESTAMP
    );

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
        p_product_id,
        'UPDATE',
        jsonb_build_object('unit_price', v_old_price),
        jsonb_build_object('unit_price', p_new_price),
        CURRENT_USER,
        CURRENT_TIMESTAMP
    );
END;
$$;


-- ============================================================
-- Q18: TEST SUCCESSFUL PRODUCT PRICE UPDATE
-- Product 71 was used in the original test.
-- ============================================================

CALL sokomart.sp_update_product_price(
    71,
    1099,
    'Price adjustment test'
);


-- ============================================================
-- Q18: VERIFY CURRENT PRODUCT PRICE
-- ============================================================

SELECT
    product_id,
    unit_price,
    cost_price
FROM sokomart.products
WHERE product_id = 71;


-- ============================================================
-- Q18: VERIFY PRODUCT PRICE HISTORY
-- ============================================================

SELECT
    product_id,
    old_price,
    new_price,
    change_reason,
    changed_by,
    changed_at
FROM sokomart.product_price_history
WHERE product_id = 71
ORDER BY changed_at DESC;


-- ============================================================
-- Q18: VERIFY PRODUCT AUDIT LOG
-- ============================================================

SELECT
    table_name,
    record_id,
    action,
    old_data,
    new_data,
    changed_by,
    changed_at
FROM sokomart.audit_logs
WHERE table_name = 'products'
  AND record_id = 71
ORDER BY changed_at DESC;


-- ============================================================
-- Q19(a): ORDER STATUS AUDIT TRIGGER FUNCTION
-- Log new orders and actual order-status changes.
-- ============================================================

CREATE OR REPLACE FUNCTION sokomart.fn_audit_order_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO sokomart.order_status_history (
            order_id,
            old_status,
            new_status,
            changed_by,
            changed_at
        )
        VALUES (
            NEW.order_id,
            NULL,
            NEW.order_status,
            CURRENT_USER,
            CURRENT_TIMESTAMP
        );

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
            'orders',
            NEW.order_id,
            'INSERT',
            NULL,
            to_jsonb(NEW),
            CURRENT_USER,
            CURRENT_TIMESTAMP
        );

    ELSIF TG_OP = 'UPDATE'
          AND OLD.order_status IS DISTINCT FROM NEW.order_status THEN

        INSERT INTO sokomart.order_status_history (
            order_id,
            old_status,
            new_status,
            changed_by,
            changed_at
        )
        VALUES (
            NEW.order_id,
            OLD.order_status,
            NEW.order_status,
            CURRENT_USER,
            CURRENT_TIMESTAMP
        );

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
            'orders',
            NEW.order_id,
            'UPDATE',
            to_jsonb(OLD),
            to_jsonb(NEW),
            CURRENT_USER,
            CURRENT_TIMESTAMP
        );

    END IF;

    RETURN NEW;
END;
$$;


-- ============================================================
-- Q19(a): CREATE ORDER STATUS AUDIT TRIGGER
-- Fire after inserts or updates to order_status.
-- ============================================================

CREATE OR REPLACE TRIGGER trg_orders_status_audit
AFTER INSERT OR UPDATE OF order_status
ON sokomart.orders
FOR EACH ROW
EXECUTE FUNCTION sokomart.fn_audit_order_status();


-- ============================================================
-- Q19(b): ORDER STATUS UPDATE PROCEDURE
-- Allowed transitions:
-- pending -> completed
-- pending -> cancelled
-- completed -> returned
-- ============================================================

CREATE OR REPLACE PROCEDURE sokomart.sp_update_order_status(
    p_order_id INTEGER,
    p_new_status VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR;
BEGIN
    SELECT order_status
    INTO v_current_status
    FROM sokomart.orders
    WHERE order_id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Order ID % does not exist',
            p_order_id;
    END IF;

    IF NOT (
        (v_current_status = 'pending'
            AND p_new_status IN ('completed', 'cancelled'))
        OR
        (v_current_status = 'completed'
            AND p_new_status = 'returned')
    ) THEN
        RAISE EXCEPTION
            'Invalid order status transition: % -> %',
            v_current_status,
            p_new_status;
    END IF;

    UPDATE sokomart.orders
    SET order_status = p_new_status
    WHERE order_id = p_order_id;

    IF p_new_status = 'completed' THEN

        UPDATE sokomart.payments
        SET payment_status = 'successful'
        WHERE order_id = p_order_id;

    ELSIF p_new_status = 'cancelled' THEN

        UPDATE sokomart.payments
        SET payment_status = 'failed'
        WHERE order_id = p_order_id
          AND payment_status = 'pending';

    END IF;
END;
$$;


-- ============================================================
-- Q19(c): CHECK INITIAL ORDER AND PAYMENT STATUS
-- Order 48882 was originally pending.
-- ============================================================

SELECT
    o.order_id,
    o.order_status,
    p.payment_status
FROM sokomart.orders AS o
LEFT JOIN sokomart.payments AS p
    ON o.order_id = p.order_id
WHERE o.order_id = 48882;


-- ============================================================
-- Q19(c): COMPLETE ORDER 48882
-- This changes the order and its payment status.
-- ============================================================

CALL sokomart.sp_update_order_status(
    48882,
    'completed'
);


-- ============================================================
-- Q19(c): VERIFY COMPLETED ORDER AND PAYMENT
-- ============================================================

SELECT
    o.order_id,
    o.order_status,
    p.payment_status
FROM sokomart.orders AS o
LEFT JOIN sokomart.payments AS p
    ON o.order_id = p.order_id
WHERE o.order_id = 48882;


-- ============================================================
-- Q19(c): VERIFY ORDER STATUS HISTORY
-- ============================================================

SELECT
    order_id,
    old_status,
    new_status,
    changed_by,
    changed_at
FROM sokomart.order_status_history
WHERE order_id = 48882
ORDER BY changed_at;


-- ============================================================
-- Q19(c): VERIFY ORDER AUDIT LOG
-- ============================================================

SELECT
    table_name,
    record_id,
    action,
    old_data,
    new_data,
    changed_by,
    changed_at
FROM sokomart.audit_logs
WHERE table_name = 'orders'
  AND record_id = 48882
ORDER BY changed_at;


-- ============================================================
-- Q19(c): TEST DIRECT STATUS UPDATE
-- Change completed order 48882 to returned.
-- The trigger should log this change too.
-- ============================================================

UPDATE sokomart.orders
SET order_status = 'returned'
WHERE order_id = 48882;

-- =====================================================
-- Q19(c): VERIFY DIRECT UPDATE
-- Check both status transitions for order 48882.
-- =====================================================

SELECT
    order_id,
    old_status,
    new_status
FROM sokomart.order_status_history
WHERE order_id = 48882
ORDER BY changed_at;
-- =====================================================
-- Q19(c): TEST UNCHANGED ORDER STATUS
-- Update shipping_county to its existing value.
-- =====================================================

UPDATE sokomart.orders
SET shipping_county = shipping_county
WHERE order_id = 48882;
-- =====================================================
-- Q19(c): VERIFY NO EXTRA STATUS HISTORY
-- Expected result: 2 records.
-- =====================================================

SELECT
    order_id,
    COUNT(*) AS history_records
FROM sokomart.order_status_history
WHERE order_id = 48882
GROUP BY order_id;
-- =====================================================
-- Q19(c): FINAL TEST — INVALID STATUS TRANSITION
-- Attempt to complete cancelled order 49961.
-- =====================================================

CALL sokomart.sp_update_order_status(49961, 'completed');


-- ============================================================
-- Q19(c): VERIFY BOTH STATUS TRANSITIONS
-- Expected: two history records.
-- ============================================================

SELECT
    order_id,
    old_status,
    new_status
FROM sokomart.order_status_history
WHERE order_id = 48882
ORDER BY changed_at;


-- ============================================================
-- Q19(c): TEST UNCHANGED ORDER STATUS
-- Updating a different column to its existing value
-- must not create another status-history record.
-- ============================================================

UPDATE sokomart.orders
SET shipping_county = shipping_county
WHERE order_id = 48882;


-- ============================================================
-- Q19(c): VERIFY NO EXTRA HISTORY RECORD
-- Expected history_records = 2.
-- ============================================================

SELECT
    order_id,
    COUNT(*) AS history_records
FROM sokomart.order_status_history
WHERE order_id = 48882
GROUP BY order_id;


-- ============================================================
-- Q19(c): TEST INVALID STATUS TRANSITION
-- Order 49961 is cancelled; completing it must fail.
-- Run separately because an exception is expected.
-- ============================================================

CALL sokomart.sp_update_order_status(
    49961,
    'completed'
);

-- =====================================================
-- Q20: ORDER PLACEMENT PROCEDURE
-- STEP 1: INSPECT REQUIRED TABLE STRUCTURES
-- =====================================================

SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'sokomart'
  AND table_name IN (
      'customers',
      'products',
      'orders',
      'order_items',
      'payments'
  )
ORDER BY
    table_name,
    ordinal_position;
-- =====================================================
-- Q20: ORDER PLACEMENT PROCEDURE
-- STEP 2: CHECK TEST PRODUCTS, PRICES AND STOCK
-- =====================================================

SELECT
    product_id,
    product_name,
    unit_price,
    stock_quantity,
    product_status
FROM sokomart.products
WHERE product_id IN (6, 73, 82, 59)
ORDER BY product_id;
-- =====================================================
-- Q20: ORDER PLACEMENT PROCEDURE
-- STEP 3: CHECK PRIMARY-KEY GENERATION
-- =====================================================

SELECT
    table_name,
    column_name,
    is_identity,
    identity_generation,
    column_default
FROM information_schema.columns
WHERE table_schema = 'sokomart'
  AND (
      (table_name = 'orders' AND column_name = 'order_id')
      OR
      (table_name = 'order_items' AND column_name = 'order_item_id')
      OR
      (table_name = 'payments' AND column_name = 'payment_id')
  )
ORDER BY table_name;

-- =====================================================
-- Q20: ORDER PLACEMENT PROCEDURE
-- STEP 4: CHECK EXISTING ID-GENERATION TRIGGERS
-- =====================================================

SELECT
    event_object_table,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'sokomart'
  AND event_object_table IN (
      'orders',
      'order_items',
      'payments'
  )
ORDER BY event_object_table, trigger_name;

-- =====================================================
-- Q20: ORDER PLACEMENT PROCEDURE
-- STEP 5: CREATE sokomart.sp_place_order
-- =====================================================

CREATE OR REPLACE PROCEDURE sokomart.sp_place_order(
    p_customer_id INTEGER,
    p_product_ids INTEGER[],
    p_quantities INTEGER[],
    p_payment_method VARCHAR,
    INOUT p_order_id INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_county VARCHAR;
    v_product_id INTEGER;
    v_quantity INTEGER;
    v_unit_price NUMERIC;
    v_available_stock INTEGER;
    v_item_subtotal NUMERIC := 0;
    v_line_total NUMERIC;
    v_delivery_fee NUMERIC;
    v_transaction_reference VARCHAR;
    v_index INTEGER;
BEGIN
    -- Validate customer existence and active status
    SELECT county
    INTO v_customer_county
    FROM sokomart.customers
    WHERE customer_id = p_customer_id
      AND customer_status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Customer ID % does not exist or is inactive',
            p_customer_id;
    END IF;

    -- Validate arrays
    IF p_product_ids IS NULL
       OR p_quantities IS NULL
       OR CARDINALITY(p_product_ids) = 0
       OR CARDINALITY(p_product_ids) <> CARDINALITY(p_quantities) THEN
        RAISE EXCEPTION
            'Product IDs and quantities must be non-empty arrays of equal length';
    END IF;

    -- Validate quantities
    IF EXISTS (
        SELECT 1
        FROM UNNEST(p_quantities) AS q(quantity)
        WHERE quantity IS NULL OR quantity <= 0
    ) THEN
        RAISE EXCEPTION
            'All quantities must be greater than zero';
    END IF;

    -- Create pending order
    INSERT INTO sokomart.orders (
        customer_id,
        order_status,
        shipping_county,
        delivery_fee,
        total_amount
    )
    VALUES (
        p_customer_id,
        'pending',
        v_customer_county,
        0,
        0
    )
    RETURNING order_id INTO p_order_id;

    -- Process each product
    FOR v_index IN 1..CARDINALITY(p_product_ids)
    LOOP
        v_product_id := p_product_ids[v_index];
        v_quantity := p_quantities[v_index];

        -- Deduct stock only when enough active stock exists
        UPDATE sokomart.products
        SET stock_quantity = stock_quantity - v_quantity
        WHERE product_id = v_product_id
          AND product_status = 'active'
          AND stock_quantity >= v_quantity
        RETURNING unit_price INTO v_unit_price;

        IF NOT FOUND THEN
            SELECT stock_quantity
            INTO v_available_stock
            FROM sokomart.products
            WHERE product_id = v_product_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION
                    'Product ID % does not exist',
                    v_product_id;
            END IF;

            IF NOT EXISTS (
                SELECT 1
                FROM sokomart.products
                WHERE product_id = v_product_id
                  AND product_status = 'active'
            ) THEN
                RAISE EXCEPTION
                    'Product ID % is inactive',
                    v_product_id;
            END IF;

            RAISE EXCEPTION
                'Insufficient stock for product %. Requested: %, available: %',
                v_product_id,
                v_quantity,
                v_available_stock;
        END IF;

        -- Calculate line total
        v_line_total := v_quantity * v_unit_price;

        -- Insert order item
        INSERT INTO sokomart.order_items (
            order_id,
            product_id,
            quantity,
            unit_price,
            discount_percentage,
            line_total
        )
        VALUES (
            p_order_id,
            v_product_id,
            v_quantity,
            v_unit_price,
            0,
            v_line_total
        );

        v_item_subtotal := v_item_subtotal + v_line_total;
    END LOOP;

    -- Calculate delivery fee
    IF v_item_subtotal >= 5000 THEN
        v_delivery_fee := 0;
    ELSIF LOWER(v_customer_county) = 'nairobi' THEN
        v_delivery_fee := 200;
    ELSIF LOWER(v_customer_county) IN (
        'kiambu', 'kajiado', 'machakos'
    ) THEN
        v_delivery_fee := 250;
    ELSE
        v_delivery_fee := 350;
    END IF;

    -- Update order totals
    UPDATE sokomart.orders
    SET
        delivery_fee = v_delivery_fee,
        total_amount = v_item_subtotal + v_delivery_fee
    WHERE order_id = p_order_id;

    -- Generate transaction reference unless cash on delivery
    IF LOWER(p_payment_method) = 'cash on delivery' THEN
        v_transaction_reference := NULL;
    ELSE
        v_transaction_reference :=
            'TXN-' || p_order_id || '-'
            || FLOOR(
                EXTRACT(EPOCH FROM CLOCK_TIMESTAMP()) * 1000
            )::BIGINT;
    END IF;

    -- Insert pending payment
    INSERT INTO sokomart.payments (
        order_id,
        payment_method,
        amount,
        payment_status,
        transaction_reference
    )
    SELECT
        p_order_id,
        p_payment_method,
        total_amount,
        'pending',
        v_transaction_reference
    FROM sokomart.orders
    WHERE order_id = p_order_id;

END;
$$;
-- =====================================================
-- Q20: SUCCESSFUL ORDER PLACEMENT TEST
-- STEP 6: PLACE ORDER FOR CUSTOMER 177
-- =====================================================

CALL sokomart.sp_place_order(
    177,
    ARRAY[6, 73, 82],
    ARRAY[1, 2, 3],
    'M-Pesa',
    NULL
);
-- =====================================================
-- Q20: VERIFY SUCCESSFUL ORDER AND PAYMENT
-- STEP 7: CHECK ORDER 50001
-- =====================================================

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.shipping_county,
    o.delivery_fee,
    o.total_amount,
    p.payment_method,
    p.amount AS payment_amount,
    p.payment_status,
    p.transaction_reference
FROM sokomart.orders o
JOIN sokomart.payments p
    ON p.order_id = o.order_id
WHERE o.order_id = 50001;
-- =====================================================
-- Q20: VERIFY ORDER ITEMS AND REMAINING STOCK
-- STEP 8: CHECK PRODUCTS 6, 73 AND 82
-- =====================================================

SELECT
    oi.product_id,
    pr.product_name,
    oi.quantity,
    oi.unit_price,
    oi.line_total,
    pr.stock_quantity AS remaining_stock
FROM sokomart.order_items oi
JOIN sokomart.products pr
    ON pr.product_id = oi.product_id
WHERE oi.order_id = 50001
ORDER BY oi.product_id;
-- =====================================================
-- Q20: VERIFY ORDER TOTAL AND PAYMENT
-- STEP 9: CHECK ORDER 50001
-- =====================================================

SELECT
    o.order_id,
    o.order_status,
    o.shipping_county,
    o.delivery_fee,
    o.total_amount,
    p.payment_method,
    p.amount AS payment_amount,
    p.payment_status,
    p.transaction_reference
FROM sokomart.orders o
JOIN sokomart.payments p
    ON p.order_id = o.order_id
WHERE o.order_id = 50001;

-- =====================================================
-- Q20: VERIFY ORDER STATUS HISTORY
-- STEP 10: CHECK STATUS AUDIT FOR ORDER 50001
-- =====================================================

SELECT
    status_history_id,
    order_id,
    old_status,
    new_status,
    changed_by,
    changed_at
FROM sokomart.order_status_history
WHERE order_id = 50001
ORDER BY changed_at;
-- =====================================================
-- Q20: RECORD BASELINE BEFORE ROLLBACK TEST
-- STEP 11: CAPTURE ORDER COUNT AND STOCK
-- =====================================================

SELECT COUNT(*) AS order_count
FROM sokomart.orders;

SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (6, 59)
ORDER BY product_id;

-- =====================================================
-- Q20: RECORD BASELINE ORDER COUNT
-- STEP 12: COUNT ORDERS BEFORE FAILURE TEST
-- =====================================================

SELECT COUNT(*) AS order_count
FROM sokomart.orders;
-- =====================================================
-- Q20: INSUFFICIENT STOCK TEST
-- STEP 13: ATTEMPT ORDER WITH INSUFFICIENT STOCK
-- =====================================================

CALL sokomart.sp_place_order(
    408,
    ARRAY[6, 59],
    ARRAY[1, 2],
    'card',
    NULL
);

-- =====================================================
-- Q20: VERIFY TRANSACTION ROLLBACK
-- STEP 14: CONFIRM ORDER COUNT AND STOCK ARE UNCHANGED
-- =====================================================

SELECT COUNT(*) AS order_count_after_failure
FROM sokomart.orders;

SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (6, 59)
ORDER BY product_id;

-- =====================================================
-- Q20: VERIFY NO ORDER WAS CREATED
-- STEP 15: CHECK ORDER COUNT AFTER ROLLBACK
-- =====================================================

SELECT COUNT(*) AS order_count_after_failure
FROM sokomart.orders;
-- =====================================================
-- Q20: COMPLETE SUCCESSFUL TEST ORDER
-- STEP 16: UPDATE ORDER 50001 TO COMPLETED
-- =====================================================

CALL sokomart.sp_update_order_status(
    50001,
    'completed'
);
-- =====================================================
-- Q20: VERIFY COMPLETED ORDER AND PAYMENT
-- STEP 17: CHECK FINAL ORDER STATUS
-- =====================================================

SELECT
    o.order_id,
    o.order_status,
    o.total_amount,
    p.payment_status,
    p.amount AS payment_amount
FROM sokomart.orders o
JOIN sokomart.payments p
    ON p.order_id = o.order_id
WHERE o.order_id = 50001;
-- =====================================================
-- Q20: REFRESH MONTHLY CATEGORY SALES
-- STEP 18: REFRESH MATERIALIZED VIEW CONCURRENTLY
-- =====================================================

REFRESH MATERIALIZED VIEW CONCURRENTLY
    sokomart.mv_monthly_category_sales;
-- =====================================================
-- Q20: VERIFY NOVEMBER 2026 CATEGORY SALES
-- STEP 19: DISPLAY REFRESHED MATERIALIZED VIEW
-- =====================================================

SELECT
    sales_month,
    category,
    orders,
    units_sold,
    revenue,
    gross_profit
FROM sokomart.mv_monthly_category_sales
WHERE sales_month = DATE '2026-11-01'
ORDER BY revenue DESC;
