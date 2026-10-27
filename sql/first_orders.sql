-- Each customer's first order, and whether (and when) they came back on a later day.
-- A second order on the same day is the same shopping trip, not a return visit.
DROP TABLE IF EXISTS first_orders;

CREATE TABLE first_orders AS
WITH valid AS (
    SELECT *
    FROM order_facts
    WHERE order_status NOT IN ('canceled', 'unavailable')
),
firsts AS (
    SELECT DISTINCT ON (customer_unique_id) *
    FROM valid
    ORDER BY customer_unique_id, purchased_at
),
returns AS (
    SELECT
        f.customer_unique_id,
        MIN(v.purchased_at) AS returned_at,
        COUNT(DISTINCT v.purchased_at::date) AS return_days
    FROM firsts f
    JOIN valid v
      ON v.customer_unique_id = f.customer_unique_id
     AND v.purchased_at::date > f.purchased_at::date
    GROUP BY f.customer_unique_id
)
SELECT
    f.order_id,
    f.customer_unique_id,
    f.customer_state,
    f.purchased_at,
    f.purchase_month AS cohort_month,
    f.category,
    f.payment_type,
    f.installments,
    f.payment_value,
    f.item_value,
    f.freight_value,
    f.order_status,
    f.delivery_days,
    f.days_late,
    f.is_late,
    f.review_score,
    r.returned_at,
    r.returned_at::date - f.purchased_at::date AS days_to_return,
    COALESCE(r.return_days, 0) AS return_days,
    COALESCE(r.returned_at < f.purchased_at + INTERVAL '180 days', FALSE) AS returned_180d
FROM firsts f
LEFT JOIN returns r USING (customer_unique_id);

ALTER TABLE first_orders ADD PRIMARY KEY (customer_unique_id);
