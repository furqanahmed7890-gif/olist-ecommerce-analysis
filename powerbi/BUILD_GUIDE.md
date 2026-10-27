# Power BI build guide

A 4-page report on the same analysis, built on the star schema from `sql/powerbi_views.sql`. Plan on about
45 minutes. Save the file as `powerbi/olist_dashboard.pbix`.

## 1. Install
Install **Power BI Desktop** (free) from the Microsoft Store.

## 2. Get the data
**Option A: straight from PostgreSQL (shows the full SQL-to-BI pipeline).**
1. Home > Get data > **PostgreSQL database**. Server `localhost`, Database `olist_db`, mode **Import**.
2. Sign in with **Database** credentials (your Postgres user and password).
3. Tick `analytics.fact_orders`, `analytics.dim_customers` and `public.app_cohort_retention`, then **Load**.
4. Rename them `fact_orders`, `dim_customers`, `cohort_retention` (double-click the table name).

**Option B: from CSV (if Option A gives a driver error).** Run notebook `06_dashboard_tables.ipynb`, then
Home > Get data > **Text/CSV** and load the three files in `powerbi/data/`.

Check the column types in Power Query: `order_date`, `purchase_month`, `cohort_month` = Date;
`is_late`, `returned_180d`, `ever_returned`, `first_order_late` = True/False; money columns = Decimal.

## 3. Model
1. Modeling > **New table**: paste the `Date` table from `measures.dax`. Table tools > **Mark as date table**
   on `Date[Date]`.
2. Model view, draw two relationships (both one-to-many, single direction):
   - `dim_customers[customer_unique_id]` 1 → * `fact_orders[customer_unique_id]`
   - `Date[Date]` 1 → * `fact_orders[order_date]`
3. Leave `cohort_retention` unconnected (it is already aggregated).
4. Select `fact_orders` > Modeling > **New measure**, and paste each measure from `measures.dax`.
   Format: `Late Rate`, `One Star Share`, `Late Share of Bad Reviews`, `Ever Returned Rate`,
   `Return Rate 180d`, `Segment Revenue Share` as **Percentage**, 1 decimal. `Revenue` as currency R$.

## 4. Pages

### Page 1: Overview
- 6 **cards**: Orders, Revenue, Customers, Ever Returned Rate, Late Rate, Avg Review Late.
- **Line and clustered column chart**: X = `Date[Month]`, columns = Revenue, line = Late Rate.
  Title: "Revenue grew 8x while late deliveries spiked around Black Friday".
- **Slicers**: `fact_orders[customer_state]` and `fact_orders[category]` (dropdown style).

### Page 2: Retention
- **Matrix** (the cohort heatmap): Rows = `cohort_retention[cohort_month]`, Columns =
  `cohort_retention[month_number]`, Values = `retention_pct` (Sum). Filter `month_number` 1 to 12.
  Cell elements > **Background color** on, gradient white to dark blue. Title: "Retention never builds".
- **Clustered bar**: Y = `dim_customers[first_category]`, X = `Return Rate 180d`, sorted descending. In
  this visual's filters, set `Customers` to "is greater than or equal to 1000" so tiny categories with
  noisy rates don't top the chart.
- **Clustered column**: X = `dim_customers[first_order_late]`, Y = `Return Rate 180d`.
- **Card**: Ever Returned Rate, subtitle "of customers ever ordered again".

### Page 3: Delivery & Reviews
- **Clustered column**: X = `fact_orders[delivery_vs_promise]` (sort ascending by that column),
  Y = Avg Review. Conditional color: red when the label contains "late". Title: "Reviews collapse once an
  order misses its promised date".
- **Clustered column**: same X, Y = One Star Share.
- **Bar**: Y = `fact_orders[customer_state]`, X = Late Rate, sorted descending.
- **Cards**: Avg Review On Time, Avg Review Late, Late Share of Bad Reviews.

### Page 4: Customer Segments
- **Clustered bar**: Y = `dim_customers[segment]`, X = Customers and Revenue (or Segment Revenue Share).
- **Table**: segment, Customers, Revenue, Avg Order Value, Avg Review.
- **Text box** with the actions table from the README.

## 5. Finish
1. View > Themes: pick one theme and keep fonts consistent. Give every visual a plain-English title.
2. Save as `powerbi/olist_dashboard.pbix`.
3. For each page, File > Export > **Export to PDF**, or take a screenshot, and save PNGs as
   `powerbi/screenshots/overview.png`, `retention.png`, `delivery.png`, `segments.png`.
   The README and the Streamlit About page pick up `overview.png` automatically.
4. Commit the `.pbix` and screenshots (the CSVs in `powerbi/data/` stay out of git).

Why no live Power BI link: "Publish to web" requires a work or school Microsoft account. The Streamlit app is
the live version; the `.pbix` and screenshots show the Power BI work.
