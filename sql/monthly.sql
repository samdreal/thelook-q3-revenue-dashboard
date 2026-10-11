-- Monthly revenue from October 2025 to September 2026 with month-over-month change,
-- for all regions and for each country. September 2025 is read only as the baseline
-- for October's change. share_of_q3 is filled for July to September only.
WITH items AS (
  SELECT
    oi.order_id,
    oi.user_id,
    oi.sale_price,
    FORMAT_DATE('%Y-%m', DATE(oi.created_at)) AS month,
    CASE u.country WHEN 'Deutschland' THEN 'Germany' WHEN 'España' THEN 'Spain' ELSE u.country END AS country
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN `bigquery-public-data.thelook_ecommerce.users` u ON u.id = oi.user_id
  WHERE oi.created_at >= TIMESTAMP '2025-09-01' AND oi.created_at < TIMESTAMP '2026-10-01'
    AND oi.status NOT IN ('Cancelled', 'Returned')
), agg AS (
  SELECT
    IF(GROUPING(country) = 1, 'All regions', country) AS scope,
    month,
    SUM(sale_price) AS rev,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT user_id) AS customers
  FROM items
  GROUP BY GROUPING SETS ((month), (country, month))
), c AS (
  SELECT
    *,
    LAG(rev) OVER (PARTITION BY scope ORDER BY month) AS prev_rev,
    LAG(orders) OVER (PARTITION BY scope ORDER BY month) AS prev_orders
  FROM agg
)
SELECT
  scope,
  month,
  ROUND(rev, 2) AS revenue,
  ROUND(rev - prev_rev, 2) AS revenue_diff,
  ROUND(SAFE_DIVIDE(rev - prev_rev, prev_rev), 4) AS revenue_mom,
  orders,
  ROUND(SAFE_DIVIDE(orders - prev_orders, prev_orders), 4) AS orders_mom,
  customers,
  ROUND(SAFE_DIVIDE(rev, orders), 2) AS avg_order_value,
  ROUND(SAFE_DIVIDE(IF(month >= '2026-07', rev, NULL), SUM(IF(month >= '2026-07', rev, 0)) OVER (PARTITION BY scope)), 4) AS share_of_q3
FROM c
WHERE month >= '2025-10'
ORDER BY scope, month
