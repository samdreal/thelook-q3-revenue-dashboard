-- Headline figures for Q3 2026 with the change from Q2 2026.
-- One row for all regions plus one row per customer country (column `scope`).
-- Revenue = sale price of items that were not cancelled or returned, by order date.
WITH items AS (
  SELECT
    oi.order_id,
    oi.user_id,
    oi.sale_price,
    oi.created_at >= TIMESTAMP '2026-07-01' AS is_q3,
    CASE u.country WHEN 'Deutschland' THEN 'Germany' WHEN 'España' THEN 'Spain' ELSE u.country END AS country
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN `bigquery-public-data.thelook_ecommerce.users` u ON u.id = oi.user_id
  WHERE oi.created_at >= TIMESTAMP '2026-04-01' AND oi.created_at < TIMESTAMP '2026-10-01'
    AND oi.status NOT IN ('Cancelled', 'Returned')
), agg AS (
  SELECT
    IF(GROUPING(country) = 1, 'All regions', country) AS scope,
    SUM(IF(is_q3, sale_price, 0)) AS rev3,
    SUM(IF(NOT is_q3, sale_price, 0)) AS rev2,
    COUNT(DISTINCT IF(is_q3, order_id, NULL)) AS ord3,
    COUNT(DISTINCT IF(NOT is_q3, order_id, NULL)) AS ord2,
    COUNT(DISTINCT IF(is_q3, user_id, NULL)) AS cus3,
    COUNT(DISTINCT IF(NOT is_q3, user_id, NULL)) AS cus2
  FROM items
  GROUP BY GROUPING SETS ((), (country))
)
SELECT
  scope,
  ROUND(rev3, 2) AS revenue,
  ROUND(SAFE_DIVIDE(rev3 - rev2, NULLIF(rev2, 0)), 4) AS revenue_change,
  ord3 AS orders,
  ROUND(SAFE_DIVIDE(ord3 - ord2, NULLIF(ord2, 0)), 4) AS orders_change,
  cus3 AS customers,
  ROUND(SAFE_DIVIDE(cus3 - cus2, NULLIF(cus2, 0)), 4) AS customers_change,
  ROUND(SAFE_DIVIDE(rev3, ord3), 2) AS avg_order_value,
  ROUND(SAFE_DIVIDE(SAFE_DIVIDE(rev3, ord3) - SAFE_DIVIDE(rev2, ord2), SAFE_DIVIDE(rev2, ord2)), 4) AS avg_order_value_change
FROM agg
WHERE rev3 > 0
ORDER BY revenue DESC
