-- A small star schema for Power BI: one fact table of orders, one customer dimension, and the cohort table.
CREATE SCHEMA IF NOT EXISTS analytics;

CREATE OR REPLACE VIEW analytics.fact_orders AS
SELECT
    order_id,
    customer_unique_id,
    purchased_at::date AS order_date,
    purchase_month,
    customer_state,
    order_status,
    category,
    payment_type,
    payment_value,
    item_value,
    freight_value,
    delivery_days,
    days_late,
    is_late,
    CASE
        WHEN days_late IS NULL THEN NULL
        WHEN days_late <= -8 THEN '1. 8+ days early'
        WHEN days_late <= -1 THEN '2. 1-7 days early'
        WHEN days_late = 0 THEN '3. on the day'
        WHEN days_late <= 3 THEN '4. 1-3 days late'
        WHEN days_late <= 7 THEN '5. 4-7 days late'
        ELSE '6. 8+ days late'
    END AS delivery_vs_promise,
    review_score,
    order_number
FROM order_facts
WHERE purchase_month BETWEEN '2017-01-01' AND '2018-08-01';

-- Every customer who placed an order, including the few whose orders were all canceled (no RFM segment).
CREATE OR REPLACE VIEW analytics.dim_customers AS
WITH customers AS (
    SELECT
        customer_unique_id,
        (ARRAY_AGG(customer_state ORDER BY purchased_at DESC))[1] AS state
    FROM order_facts
    GROUP BY customer_unique_id
)
SELECT
    c.customer_unique_id,
    c.state,
    COALESCE(r.segment, '8. No completed order') AS segment,
    r.r_score,
    r.f_score,
    r.m_score,
    r.monetary,
    r.recency_days,
    f.cohort_month,
    f.category AS first_category,
    f.is_late AS first_order_late,
    f.review_score AS first_review_score,
    f.returned_180d,
    f.returned_at IS NOT NULL AS ever_returned
FROM customers c
LEFT JOIN customer_rfm r USING (customer_unique_id)
LEFT JOIN first_orders f USING (customer_unique_id);
