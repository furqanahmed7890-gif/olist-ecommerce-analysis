-- Review scores by how early or late the order arrived compared with the promised date.
WITH delivered AS (
    SELECT
        days_late,
        review_score,
        CASE
            WHEN days_late <= -15 THEN '01. 15+ days early'
            WHEN days_late <= -8 THEN '02. 8-14 days early'
            WHEN days_late <= -1 THEN '03. 1-7 days early'
            WHEN days_late = 0 THEN '04. on the day'
            WHEN days_late <= 3 THEN '05. 1-3 days late'
            WHEN days_late <= 7 THEN '06. 4-7 days late'
            WHEN days_late <= 14 THEN '07. 8-14 days late'
            ELSE '08. 15+ days late'
        END AS delivery_vs_promise
    FROM order_facts
    WHERE order_status = 'delivered'
      AND days_late IS NOT NULL
      AND review_score IS NOT NULL
)
SELECT
    delivery_vs_promise,
    COUNT(*) AS orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders,
    ROUND(AVG(review_score), 2) AS avg_review,
    ROUND(AVG(CASE WHEN review_score = 1 THEN 1.0 ELSE 0 END) * 100, 1) AS one_star_pct,
    ROUND(AVG(CASE WHEN review_score = 5 THEN 1.0 ELSE 0 END) * 100, 1) AS five_star_pct
FROM delivered
GROUP BY delivery_vs_promise
ORDER BY delivery_vs_promise;
