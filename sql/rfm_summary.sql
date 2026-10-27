-- Size, value, and satisfaction of each RFM segment.
SELECT
    segment,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers,
    ROUND(SUM(monetary), 0) AS revenue,
    ROUND(SUM(monetary) * 100.0 / SUM(SUM(monetary)) OVER (), 1) AS pct_of_revenue,
    ROUND(AVG(monetary), 0) AS avg_spend,
    ROUND(AVG(recency_days), 0) AS avg_days_since_last_order,
    ROUND(AVG(avg_review), 2) AS avg_review
FROM customer_rfm
GROUP BY segment
ORDER BY segment;
