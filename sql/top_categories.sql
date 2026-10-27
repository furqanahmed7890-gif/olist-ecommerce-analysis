-- Top 15 categories by revenue, with each one's share of the total (a window function over the aggregate).
SELECT
    category,
    COUNT(*) AS orders,
    ROUND(SUM(payment_value), 0) AS revenue,
    ROUND(SUM(payment_value) * 100.0 / SUM(SUM(payment_value)) OVER (), 1) AS revenue_share_pct,
    ROUND(AVG(review_score), 2) AS avg_review,
    ROUND(AVG(CASE WHEN is_late THEN 1.0 ELSE 0 END) * 100, 1) AS late_pct
FROM order_facts
WHERE order_status = 'delivered'
GROUP BY category
ORDER BY revenue DESC
LIMIT 15;
