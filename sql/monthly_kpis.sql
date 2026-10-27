-- Monthly business overview: orders, revenue, customers, and how many of them had bought before.
WITH monthly AS (
    SELECT
        purchase_month,
        COUNT(*) AS orders,
        SUM(payment_value) AS revenue,
        COUNT(DISTINCT customer_unique_id) AS customers,
        COUNT(DISTINCT CASE WHEN order_number > 1 THEN customer_unique_id END) AS returning_customers,
        AVG(CASE WHEN is_late THEN 1.0 ELSE 0 END) AS late_rate,
        AVG(review_score) AS avg_review
    FROM order_facts
    WHERE purchase_month BETWEEN '2017-01-01' AND '2018-08-01'
      AND order_status NOT IN ('canceled', 'unavailable')
    GROUP BY purchase_month
)
SELECT
    purchase_month,
    orders,
    ROUND(revenue, 0) AS revenue,
    ROUND(revenue / orders, 2) AS avg_order_value,
    customers,
    ROUND(returning_customers * 100.0 / customers, 2) AS returning_pct,
    ROUND(late_rate * 100, 1) AS late_pct,
    ROUND(avg_review, 2) AS avg_review,
    ROUND((revenue / LAG(revenue) OVER (ORDER BY purchase_month) - 1) * 100, 1) AS revenue_growth_pct
FROM monthly
ORDER BY purchase_month;
