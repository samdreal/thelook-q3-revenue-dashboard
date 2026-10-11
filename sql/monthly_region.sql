-- Revenue per month in Q3 2026 by region.
-- scope = 'All regions': the five largest countries plus 'All other'.
-- scope = a country: that country alone.
WITH items AS (
  SELECT
    oi.sale_price,
    FORMAT_DATE('%Y-%m', DATE(oi.created_at)) AS month,
    CASE u.country WHEN 'Deutschland' THEN 'Germany' WHEN 'España' THEN 'Spain' ELSE u.country END AS country
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN `bigquery-public-data.thelook_ecommerce.users` u ON u.id = oi.user_id
  WHERE oi.created_at >= TIMESTAMP '2026-07-01' AND oi.created_at < TIMESTAMP '2026-10-01'
    AND oi.status NOT IN ('Cancelled', 'Returned')
), top AS (
  SELECT country FROM items GROUP BY country ORDER BY SUM(sale_price) DESC LIMIT 5
)
SELECT
  'All regions' AS scope,
  month,
  IF(country IN (SELECT country FROM top), country, 'All other') AS region,
  ROUND(SUM(sale_price), 2) AS revenue
FROM items
GROUP BY month, region
UNION ALL
SELECT country AS scope, month, country AS region, ROUND(SUM(sale_price), 2) AS revenue
FROM items
GROUP BY country, month
ORDER BY scope, month, revenue DESC
