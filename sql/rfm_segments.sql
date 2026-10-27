-- RFM segmentation: Recency, Frequency, Monetary value for every customer.
-- NTILE(5) ranks customers into fifths on recency and spend. Almost everyone bought once, so
-- frequency only separates "bought once" from "came back".
DROP TABLE IF EXISTS customer_rfm;

CREATE TABLE customer_rfm AS
WITH reference AS (
    SELECT MAX(purchased_at)::date + 1 AS as_of
    FROM order_facts
),
customer_stats AS (
    SELECT
        customer_unique_id,
        (ARRAY_AGG(customer_state ORDER BY purchased_at DESC))[1] AS state,
        MAX(purchased_at) AS last_order_at,
        COUNT(DISTINCT purchased_at::date) AS purchase_days,
        SUM(payment_value) AS monetary,
        AVG(review_score) AS avg_review
    FROM order_facts
    WHERE order_status NOT IN ('canceled', 'unavailable')
      AND payment_value IS NOT NULL
    GROUP BY customer_unique_id
),
scored AS (
    SELECT
        s.*,
        r.as_of - s.last_order_at::date AS recency_days,
        NTILE(5) OVER (ORDER BY s.last_order_at) AS r_score,
        CASE WHEN s.purchase_days >= 3 THEN 3 WHEN s.purchase_days = 2 THEN 2 ELSE 1 END AS f_score,
        NTILE(5) OVER (ORDER BY s.monetary) AS m_score
    FROM customer_stats s
    CROSS JOIN reference r
)
SELECT
    *,
    CASE
        WHEN f_score >= 2 AND r_score >= 4 THEN '1. Loyal'
        WHEN f_score >= 2 THEN '2. Repeat, going quiet'
        WHEN r_score >= 4 AND m_score >= 4 THEN '3. New big spender'
        WHEN r_score >= 4 THEN '4. New'
        WHEN r_score = 3 THEN '5. Cooling off'
        WHEN m_score >= 4 THEN '6. Lost big spender'
        ELSE '7. Lost'
    END AS segment
FROM scored;

ALTER TABLE customer_rfm ADD PRIMARY KEY (customer_unique_id);
