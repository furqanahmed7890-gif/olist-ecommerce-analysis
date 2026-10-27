-- One row per order: the real customer behind it, what was bought, how delivery went, and the review.
-- Every later analysis starts from this table.
DROP TABLE IF EXISTS order_facts CASCADE;

CREATE TABLE order_facts AS
WITH items AS (
    SELECT
        order_id,
        COUNT(*) AS items,
        SUM(price) AS item_value,
        SUM(freight_value) AS freight_value,
        COUNT(DISTINCT seller_id) AS sellers
    FROM order_items
    GROUP BY order_id
),
main_item AS (
    -- the most expensive item decides the order's category and main seller
    SELECT order_id, category, seller_id
    FROM (
        SELECT
            i.order_id,
            i.seller_id,
            COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
            ROW_NUMBER() OVER (PARTITION BY i.order_id ORDER BY i.price DESC, i.order_item_id) AS rn
        FROM order_items i
        JOIN products p USING (product_id)
        LEFT JOIN category_translation t USING (product_category_name)
    ) ranked
    WHERE rn = 1
),
payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS payment_value,
        MAX(payment_installments) AS installments,
        (ARRAY_AGG(payment_type ORDER BY payment_value DESC))[1] AS payment_type
    FROM order_payments
    GROUP BY order_id
),
latest_review AS (
    -- a few orders were reviewed twice; keep the latest answer
    SELECT order_id, review_score
    FROM (
        SELECT
            order_id,
            review_score,
            ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS rn
        FROM order_reviews
    ) ranked
    WHERE rn = 1
)
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp AS purchased_at,
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS purchase_month,
    o.order_delivered_customer_date AS delivered_at,
    o.order_estimated_delivery_date AS estimated_at,
    i.items,
    i.item_value,
    i.freight_value,
    i.sellers,
    m.category,
    m.seller_id AS main_seller_id,
    p.payment_value,
    p.payment_type,
    p.installments,
    ROUND((EXTRACT(EPOCH FROM o.order_delivered_customer_date - o.order_purchase_timestamp) / 86400)::numeric, 1)
        AS delivery_days,
    o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date AS days_late,
    o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date AS is_late,
    r.review_score,
    ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS order_number,
    COUNT(*) OVER (PARTITION BY c.customer_unique_id) AS customer_orders
FROM orders o
JOIN customers c USING (customer_id)
LEFT JOIN items i USING (order_id)
LEFT JOIN main_item m USING (order_id)
LEFT JOIN payments p USING (order_id)
LEFT JOIN latest_review r USING (order_id);

ALTER TABLE order_facts ADD PRIMARY KEY (order_id);
CREATE INDEX ON order_facts (customer_unique_id);
CREATE INDEX ON order_facts (purchase_month);
