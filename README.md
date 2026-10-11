# Q3 2026 Revenue Dashboard: TheLook E-commerce

**[View the live dashboard →](https://samdreal.github.io/thelook-q3-revenue-dashboard/)**

An interactive revenue dashboard for Q3 2026 (July to September), built on Google's
[TheLook e-commerce](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce)
public dataset in BigQuery. TheLook is a fictitious clothing store; the data is
generated and refreshed daily by Google.

The page is a single static HTML file. It runs from a saved data snapshot, so it
opens in any browser or on GitHub Pages without a server or Google Cloud
credentials. A Python script re-runs the SQL to refresh the snapshot.

## What it shows

- **Headline figures:** Q3 revenue, orders, customers who bought and average order value, each with its change from Q2 2026.
- **Region filter:** pick a country from the drop-down, or click a country's bar or table row. Every section updates to that country, except the revenue-by-country chart and the country table, which keep every country for comparison and highlight the one picked.
- **Month-to-month revenue:** a 12-month revenue trend (October 2025 to September 2026) with Q3 shaded, the month-over-month change as bars, and a July / August / September breakdown with orders, customers and average order value.
- **Revenue by country:** every country with Q3 sales, with its share of the total.
- **Monthly revenue by region:** the five largest countries plus "All other", per month.
- **Top 10 product categories** by Q3 revenue.
- **Country detail table:** Q3 revenue, orders, share, Q2 revenue and change.

## Key findings (snapshot of 11 October 2026)

| Metric | Q3 2026 | vs Q2 2026 |
|---|---|---|
| Revenue | $1.05M | +41.5% |
| Orders | 12,180 | +41.3% |
| Customers who bought | 10,733 | +33.3% |
| Average order value | $86.23 | +0.2% |

- China (33.9%), the United States (22.9%) and Brasil (14.2%) bring in over 70% of revenue.
- Revenue grew every month of Q3 (+11.4% in July, +10.5% in August, +25.1% in September). The growth came mostly from more orders; average order value barely moved.
- Outerwear & Coats and Jeans are the top categories, at about 12% of revenue each.

## Metric definitions

- **Revenue:** the sum of `order_items.sale_price` for items whose status is not `Cancelled` or `Returned`, counted by the item's order date (`created_at`).
- **Orders / customers:** distinct `order_id` / `user_id` among those items.
- **Average order value:** revenue ÷ orders.
- **Region:** the customer's home country (`users.country`). The data spells a few customers' countries as `Deutschland` and `España`; these are counted as Germany and Spain. `Brasil` is the dataset's own spelling.
- **Share** of a category: its share of all Q3 revenue across every category, so the top 10 add up to about two thirds, not 100%.
- **Month-over-month change** compares each month with the one before (July with June). For very small countries a month with no sales is skipped, so the change is against the last month that had sales.

## Project structure

```
├── index.html              # the dashboard (static, uses d3 from cdnjs)
├── data/data.js            # data snapshot the page reads
├── sql/                    # one query per dataset, runnable in the BigQuery console
│   ├── kpis.sql
│   ├── by_country.sql
│   ├── monthly_region.sql
│   ├── by_category.sql
│   └── monthly.sql
├── scripts/refresh_data.py # re-runs the SQL and rewrites data/data.js
└── requirements.txt
```

Each query returns one set of rows for `All regions` plus one per country
(the `scope` column, built with `GROUPING SETS`). That is what lets the region
filter work in a static page with no database behind it.

## View it

The dashboard is published with GitHub Pages at
**https://samdreal.github.io/thelook-q3-revenue-dashboard/**.

To run it locally, open `index.html` in a browser. It works straight from the file system,
but needs an internet connection to load d3 and the fonts.

## Refresh the data

You need Python 3, the [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
(for the `gcloud` sign-in below) and a Google Cloud project with the BigQuery API enabled.
The free BigQuery sandbox works. Each query scans about 50 MB, well inside the free tier.

```bash
pip install -r requirements.txt
gcloud auth application-default login
python scripts/refresh_data.py --project YOUR_GCP_PROJECT_ID
```

Then commit the updated `data/data.js`.

The quarter is fixed in the SQL (Q3 2026, compared with Q2 2026, and a trend
from October 2025). Refreshing updates the numbers for that same quarter. To report on
another quarter, change the dates in the `sql/` files, and in `index.html` the
`'2026-07'` month checks, the month tiles' `month=2026-…` values and the labels that
name Q3 2026 or its months.

## Built with

- BigQuery Standard SQL
- [d3.js](https://d3js.org/) 7.9 for the charts
- Python and `google-cloud-bigquery` for the refresh script
