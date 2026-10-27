-- How concentrated are late deliveries? Rank sellers by their late deliveries and accumulate.
WITH seller_stats AS (
    SELECT
        main_seller_id AS seller_id,
        COUNT(*) AS delivered_orders,
        SUM(CASE WHEN is_late THEN 1 ELSE 0 END) AS late_orders
    FROM order_facts
    WHERE order_status = 'delivered' AND is_late IS NOT NULL
    GROUP BY main_seller_id
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY late_orders DESC, delivered_orders) AS seller_rank,
        COUNT(*) OVER () AS sellers,
        SUM(late_orders) OVER () AS all_late,
        SUM(delivered_orders) OVER () AS all_delivered,
        SUM(late_orders) OVER (ORDER BY late_orders DESC, delivered_orders
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_late,
        SUM(delivered_orders) OVER (ORDER BY late_orders DESC, delivered_orders
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_delivered
    FROM seller_stats
)
SELECT
    seller_rank,
    ROUND(seller_rank * 100.0 / sellers, 1) AS top_pct_of_sellers,
    ROUND(cumulative_late * 100.0 / all_late, 1) AS pct_of_late_deliveries,
    ROUND(cumulative_delivered * 100.0 / all_delivered, 1) AS pct_of_all_deliveries
FROM ranked
WHERE seller_rank IN (10, 25, 50, 100, 155, 310, 500)
ORDER BY seller_rank;
