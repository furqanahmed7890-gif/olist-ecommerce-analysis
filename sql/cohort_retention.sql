-- Monthly cohort retention: of the customers whose first order was in a given month,
-- what share ordered again 1, 2, 3... months later?
WITH activity AS (
    SELECT DISTINCT
        f.customer_unique_id,
        f.cohort_month,
        (EXTRACT(YEAR FROM AGE(o.purchase_month, f.cohort_month)) * 12
         + EXTRACT(MONTH FROM AGE(o.purchase_month, f.cohort_month)))::int AS month_number
    FROM first_orders f
    JOIN order_facts o USING (customer_unique_id)
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS customers
    FROM first_orders
    GROUP BY cohort_month
)
SELECT
    a.cohort_month,
    s.customers AS cohort_customers,
    a.month_number,
    COUNT(*) AS active_customers,
    ROUND(COUNT(*) * 100.0 / s.customers, 2) AS retention_pct
FROM activity a
JOIN cohort_size s USING (cohort_month)
WHERE a.cohort_month BETWEEN '2017-01-01' AND '2018-08-01'
  AND a.cohort_month + (a.month_number || ' months')::interval <= DATE '2018-08-01'
GROUP BY a.cohort_month, s.customers, a.month_number
ORDER BY a.cohort_month, a.month_number;
