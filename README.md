# Olist E-Commerce: Why Customers Don't Come Back

**Live demo: [olist-ecommerce-analysis-fa.streamlit.app](https://olist-ecommerce-analysis-fa.streamlit.app/)**

An end-to-end SQL analysis of 99,441 real orders from Olist, a Brazilian online marketplace (2016-2018),
answering two business questions:

1. **Why don't customers come back?**
2. **How much does late delivery hurt review scores?**

Built on PostgreSQL (relational schema, CTEs, window functions), presented in a Streamlit app and a
Power BI report.

![Review scores by delivery vs. promised date](images/review_by_delay.png)

## The answers

**Why don't customers come back?** Only **2.2% of customers ever ordered again**. Retention never
builds: about 0.5% of each monthly cohort returns the next month, then 0.2-0.3% a month. Even customers
whose first order arrived on time and got 5 stars came back only about 2% of the time, so the main reason
isn't a bad experience. Olist is used for one-off purchases and nothing pulls customers back. What was
bought matters most: home categories (bed/bath/table, sports, furniture) bring people back about **2.7x**
more often than gadgets. A late first delivery cuts the return rate by about 20%.

**How much does late delivery hurt reviews?** A lot. Late orders average **2.27 stars vs. 4.29** on time.
The drop starts the day the promise is missed, and past a week late about **70% of reviews are 1-star**.
Late orders are only 6.7% of deliveries but **32.5% of all 1-2 star reviews**. Customers judge the promise,
not the wait: a slow order that arrives on time beats a faster one that arrives late.

## What it shows
- **Schema design:** 8 tables with primary keys, foreign keys, and check constraints
  ([`sql/schema.sql`](sql/schema.sql)), bulk-loaded with `COPY`, every row count and key verified.
- **Real SQL:** CTEs, `JOIN`s across 5 tables, window functions (`ROW_NUMBER`, `NTILE`, `LAG`,
  `COUNT/SUM OVER`, running totals with `ROWS BETWEEN`), `DISTINCT ON`, `PERCENTILE_CONT`, `UNION ALL`.
  Every query lives in [`sql/`](sql/).
- **Analytical care:** catching that `customer_id` is per order (99,441 IDs, 96,096 real people), a fair
  180-day window for return rates, 95% confidence intervals, and same-day orders not counted as returns.
- **Dashboards:** a 5-page Streamlit app that shows the SQL behind every chart, and a Power BI star schema
  with DAX measures.

## Key findings

| | |
|---|---|
| ![Cohort retention](images/cohort_retention.png) | ![Return drivers](images/return_drivers.png) |
| ![Monthly revenue](images/monthly_revenue.png) | ![Late deliveries by state](images/late_by_state.png) |

- **Growth came from new customers only.** Revenue grew about 8x (R\$137k in Jan 2017 to R\$1.0-1.2M a
  month in 2018) while returning customers stayed at about 3% of each month's buyers.
- **Late-delivery spikes hit reviews.** Late deliveries jumped around Black Friday 2017 (12%) and in
  Feb-Mar 2018 (14-18%), and the average review fell in the same months.
- **Lateness is mostly geographic:** Alagoas 21% late, Maranhão 17%, vs. São Paulo 4.5%. Rio de Janeiro is
  the worst big state at 12%.
- **RFM:** "New big spenders" are 15.5% of customers but **28.4% of revenue**: the best target for a
  second-order campaign.

## Recommendations
1. **Keep promises, don't chase speed.** Pad delivery estimates more for north-eastern states and Rio, and
   flag the few sellers late more than 15% of the time (3.66 stars vs. 4.28 for reliable sellers).
2. **Give customers a reason to return.** A second-order offer 2-3 months after the first purchase
   (the median return is 74 days), aimed at new big spenders and home categories.
3. **Recover bad first experiences** with a service message before any discount: late, poorly rated first
   orders are the least likely to come back.

## Project structure

```
01_load_postgres.ipynb       Schema, COPY load, data quality checks
02_order_facts.ipynb         One row per order (CTEs + window functions), business overview
03_retention.ipynb           Cohorts, time to return, what the first order predicts
04_delivery_reviews.ipynb    Review scores vs. lateness, wait vs. promise, where lateness happens
05_rfm_segments.ipynb        RFM segments with NTILE and recommended actions
06_dashboard_tables.ipynb    Summary tables for the app, Power BI star schema and CSV export
sql/                         Every query: schema, order_facts, cohorts, RFM, Power BI views...
app.py                       Streamlit entry point (5 pages: overview, retention, delivery, segments, about)
db.py                        PostgreSQL if configured, else the bundled SQLite snapshot
app_data/                    Snapshot of the app's summary tables (runs the public demo)
powerbi/                     DAX measures, build guide, report and screenshots
images/                      Charts used in this README
```

## Run it locally
1. Download the [Olist dataset from Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
   and unzip the CSVs into `data/raw/`.
2. Create a PostgreSQL database and a `.env` file:
   ```
   DATABASE_URL=postgresql+psycopg2://postgres:your_password@localhost:5432/olist_db
   ```
3. Install and run:
   ```bash
   python -m venv .venv
   .venv\Scripts\activate
   pip install -r requirements.txt matplotlib ipykernel
   ```
4. Run the notebooks in order (01 → 06), then:
   ```bash
   streamlit run app.py
   ```

## Power BI
The report is built on three tables from [`sql/powerbi_views.sql`](sql/powerbi_views.sql) (`fact_orders`,
`dim_customers`, `cohort_retention`) with the measures in [`powerbi/measures.dax`](powerbi/measures.dax).
[`powerbi/BUILD_GUIDE.md`](powerbi/BUILD_GUIDE.md) has the step-by-step build.

## Limitations
- Observational data: the link between a late first delivery and not returning is a correlation, not an
  experiment.
- The data ends in August 2018, so recent customers had little time to return; return rates use a fixed
  180-day window to stay fair.
- Revenue is payment value, not profit, in Brazilian reais.

## Tech stack
PostgreSQL, SQL, Python, pandas, SQLAlchemy, Streamlit, Altair, Power BI (DAX)
