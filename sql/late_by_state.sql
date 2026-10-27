-- Late delivery rate, delivery time, and reviews by customer state (states with 300+ deliveries).
SELECT
    customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(CASE WHEN is_late THEN 1.0 ELSE 0 END) * 100, 1) AS late_pct,
    ROUND(AVG(delivery_days), 1) AS avg_delivery_days,
    ROUND(AVG(review_score), 2) AS avg_review
FROM order_facts
WHERE order_status = 'delivered' AND is_late IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) >= 300
ORDER BY late_pct DESC;
