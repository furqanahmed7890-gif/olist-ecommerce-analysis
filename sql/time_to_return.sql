-- For customers who came back: how long did it take?
SELECT
    COUNT(*) AS returning_customers,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_to_return) AS p25_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY days_to_return) AS median_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_to_return) AS p75_days,
    ROUND(AVG(CASE WHEN days_to_return <= 30 THEN 1.0 ELSE 0 END) * 100, 1) AS within_30d_pct,
    ROUND(AVG(CASE WHEN days_to_return <= 90 THEN 1.0 ELSE 0 END) * 100, 1) AS within_90d_pct,
    ROUND(AVG(CASE WHEN days_to_return <= 180 THEN 1.0 ELSE 0 END) * 100, 1) AS within_180d_pct
FROM first_orders
WHERE returned_at IS NOT NULL;
