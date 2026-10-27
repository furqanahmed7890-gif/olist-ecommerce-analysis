-- Do customers judge the actual wait, or whether the promised date was kept?
SELECT
    CASE
        WHEN delivery_days < 7 THEN '1. under 7 days'
        WHEN delivery_days < 14 THEN '2. 7-13 days'
        WHEN delivery_days < 21 THEN '3. 14-20 days'
        WHEN delivery_days < 30 THEN '4. 21-29 days'
        ELSE '5. 30+ days'
    END AS actual_wait,
    CASE WHEN is_late THEN 'Late' ELSE 'On time' END AS vs_promise,
    COUNT(*) AS orders,
    ROUND(AVG(review_score), 2) AS avg_review
FROM order_facts
WHERE order_status = 'delivered' AND is_late IS NOT NULL AND review_score IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2;
