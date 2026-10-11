-- Top 10 product categories by Q3 2026 revenue, for all regions and for each country.
-- share = share of that scope's total Q3 revenue across every category.
WITH items AS (
  SELECT
    oi.order_id,
    oi.sale_price,
    p.category,
    oi.created_at >= TIMESTAMP '2026-07-01' AS is_q3,
    CASE u.country WHEN 'Deutschland' THEN 'Germany' WHEN 'España' THEN 'Spain' ELSE u.country END AS country
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN `bigquery-public-data.thelook_ecommerce.products` p ON p.id = oi.product_id
  JOIN `bigquery-public-data.thelook_ecommerce.users` u ON u.id = oi.user_id
  WHERE oi.created_at >= TIMESTAMP '2026-04-01' AND oi.created_at < TIMESTAMP '2026-10-01'
    AND oi.status NOT IN ('Cancelled', 'Returned')
), agg AS (
  SELECT
    IF(GROUPING(country) = 1, 'All regions', country) AS scope,
    category,
    SUM(IF(is_q3, sale_price, 0)) AS rev3,
    SUM(IF(NOT is_q3, sale_price, 0)) AS rev2,
    COUNT(DISTINCT IF(is_q3, order_id, NULL)) AS orders
  FROM items
  GROUP BY GROUPING SETS ((category), (country, category))
), ranked AS (
  SELECT
    *,
    SAFE_DIVIDE(rev3, SUM(rev3) OVER (PARTITION BY scope)) AS share,
    ROW_NUMBER() OVER (PARTITION BY scope ORDER BY rev3 DESC) AS rnk
  FROM agg
  WHERE rev3 > 0
)
SELECT
  scope,
  category,
  ROUND(rev3, 2) AS revenue,
  orders,
  ROUND(share, 4) AS share,
  ROUND(SAFE_DIVIDE(rev3 - rev2, NULLIF(rev2, 0)), 4) AS change_vs_q2
FROM ranked
WHERE rnk <= 10
ORDER BY scope, revenue DESC
