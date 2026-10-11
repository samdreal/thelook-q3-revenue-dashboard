-- Q3 2026 revenue, orders and share of total per customer country,
-- with Q2 2026 revenue and the quarter-on-quarter change.
WITH items AS (
  SELECT
    oi.order_id,
    oi.sale_price,
    oi.created_at >= TIMESTAMP '2026-07-01' AS is_q3,
    CASE u.country WHEN 'Deutschland' THEN 'Germany' WHEN 'España' THEN 'Spain' ELSE u.country END AS country
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN `bigquery-public-data.thelook_ecommerce.users` u ON u.id = oi.user_id
  WHERE oi.created_at >= TIMESTAMP '2026-04-01' AND oi.created_at < TIMESTAMP '2026-10-01'
    AND oi.status NOT IN ('Cancelled', 'Returned')
)
SELECT
  country,
  ROUND(SUM(IF(is_q3, sale_price, 0)), 2) AS revenue,
  COUNT(DISTINCT IF(is_q3, order_id, NULL)) AS orders,
  ROUND(SAFE_DIVIDE(SUM(IF(is_q3, sale_price, 0)), SUM(SUM(IF(is_q3, sale_price, 0))) OVER ()), 4) AS share,
  ROUND(SUM(IF(NOT is_q3, sale_price, 0)), 2) AS revenue_q2,
  ROUND(SAFE_DIVIDE(SUM(IF(is_q3, sale_price, 0)) - SUM(IF(NOT is_q3, sale_price, 0)), NULLIF(SUM(IF(NOT is_q3, sale_price, 0)), 0)), 4) AS change_vs_q2
FROM items
GROUP BY country
HAVING SUM(IF(is_q3, sale_price, 0)) > 0
ORDER BY revenue DESC
