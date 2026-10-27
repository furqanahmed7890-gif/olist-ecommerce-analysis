-- Headline numbers for the whole marketplace.
WITH delivered AS (
    SELECT is_late, review_score
    FROM order_facts
    WHERE order_status = 'delivered' AND is_late IS NOT NULL
)
SELECT
    (SELECT COUNT(*) FROM order_facts) AS orders,
    (SELECT COUNT(DISTINCT customer_unique_id) FROM order_facts) AS customers,
    (SELECT ROUND(SUM(payment_value), 0) FROM order_facts WHERE order_status NOT IN ('canceled', 'unavailable')) AS revenue,
    (SELECT ROUND(AVG(CASE WHEN returned_at IS NOT NULL THEN 1.0 ELSE 0 END) * 100, 2) FROM first_orders) AS returned_pct,
    (SELECT ROUND(AVG(CASE WHEN is_late THEN 1.0 ELSE 0 END) * 100, 2) FROM delivered) AS late_pct,
    (SELECT ROUND(AVG(review_score), 2) FROM delivered WHERE NOT is_late) AS avg_review_on_time,
    (SELECT ROUND(AVG(review_score), 2) FROM delivered WHERE is_late) AS avg_review_late,
    (SELECT ROUND(SUM(CASE WHEN is_late AND review_score <= 2 THEN 1 ELSE 0 END) * 100.0
                  / SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 1) FROM delivered) AS late_share_of_bad_reviews_pct;
