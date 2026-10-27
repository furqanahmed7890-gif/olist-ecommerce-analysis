-- 180-day return rate by what happened on the customer's first order, with 95% confidence intervals.
-- Only first orders from January 2017 to February 2018, so every customer had a full 180 days to return.
WITH eligible AS (
    SELECT *
    FROM first_orders
    WHERE cohort_month BETWEEN '2017-01-01' AND '2018-02-01'
),
labelled AS (
    SELECT 'First delivery' AS dimension, CASE WHEN is_late THEN 'Late' ELSE 'On time' END AS value, returned_180d
    FROM eligible
    WHERE order_status = 'delivered' AND is_late IS NOT NULL
    UNION ALL
    SELECT 'First review score', review_score || ' stars', returned_180d
    FROM eligible
    WHERE review_score IS NOT NULL
    UNION ALL
    SELECT 'First order category', category, returned_180d
    FROM eligible
    UNION ALL
    SELECT 'Customer state', customer_state, returned_180d
    FROM eligible
    UNION ALL
    SELECT
        'First order value',
        CASE
            WHEN payment_value < 50 THEN '1. under R$50'
            WHEN payment_value < 100 THEN '2. R$50-100'
            WHEN payment_value < 200 THEN '3. R$100-200'
            ELSE '4. R$200+'
        END,
        returned_180d
    FROM eligible
    WHERE payment_value IS NOT NULL
),
rates AS (
    SELECT
        dimension,
        value,
        COUNT(*) AS customers,
        AVG(CASE WHEN returned_180d THEN 1.0 ELSE 0 END) AS rate
    FROM labelled
    GROUP BY dimension, value
    HAVING COUNT(*) >= 1000
)
SELECT
    dimension,
    value,
    customers,
    ROUND(rate * 100, 2) AS return_180d_pct,
    ROUND(1.96 * SQRT(rate * (1 - rate) / customers) * 100, 2) AS ci95_pct
FROM rates
ORDER BY dimension, return_180d_pct DESC;
