from pathlib import Path

import streamlit as st

st.title("About This Project")

st.markdown(r"""
An end-to-end SQL analysis of a real e-commerce marketplace, answering two business questions:
**why don't customers come back**, and **how much does late delivery hurt review scores?**

### The data
The [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce):
99,441 real orders placed on Olist between 2016 and 2018, split across 8 linked tables (customers, orders,
order items, payments, reviews, products, sellers, and a category translation).

### How it was built
1. **Schema design.** A relational schema in PostgreSQL with primary keys, foreign keys, and check
   constraints (`sql/schema.sql`), bulk-loaded with `COPY`. Row counts and every foreign key verified.
2. **One row per order.** `order_facts` flattens five tables with CTEs and window functions:
   `ROW_NUMBER()` picks each order's main item and latest review and numbers each customer's orders;
   `COUNT(*) OVER (PARTITION BY ...)` gives lifetime order counts.
3. **The customer trap.** Olist issues a new `customer_id` for every order. The 99,441 IDs belong to
   96,096 real people, so all retention work uses `customer_unique_id`.
4. **Retention.** Monthly cohorts, time to second order with `PERCENTILE_CONT`, and 180-day return rates
   (with 95% confidence intervals) by what happened on the first order. `DISTINCT ON` picks each customer's
   first order.
5. **Delivery vs. reviews.** Review scores by days early or late against the promised date, wait time vs.
   promise, late rates by state, and a seller Pareto with running `SUM() OVER`.
6. **RFM segments** with `NTILE(5)`, adapted for a business where 97% of customers buy once.
7. **Dashboards.** Summary tables for this app, and an `analytics` star schema (fact orders, customer
   dimension, cohorts) for a Power BI report.

### Key findings
- Only **2.2% of customers ever ordered again**. Retention never builds: about 0.5% of a cohort returns the
  next month, then 0.2-0.3% a month.
- Even a perfect first order (on time, 5 stars) brings customers back only about 2% of the time. Home categories
  bring them back 2.7x more often than gadgets. A late first delivery cuts the return rate by about 20%.
- Late orders average **2.27 stars vs. 4.29** on time. Past a week late, about 70% of reviews are 1-star.
  Late orders are 6.7% of deliveries but **32.5% of all 1-2 star reviews**.
- Customers judge the promise, not the wait: a slow order that arrives on time beats a faster late one.
- **New big spenders** (15.5% of customers, 28.4% of revenue) are the best target for a second-order campaign.

### Limitations
- Observational data: the late-delivery effect on returns is a correlation, not a controlled experiment.
- The data ends in August 2018, so recent cohorts have little time to return; return rates use a fixed
  180-day window for fairness.
- Reviews exist for about 99% of orders, but customers who never reviewed may differ from those who did.
- Revenue is payment value in Brazilian reais (R\$), not profit.

### Tech stack
PostgreSQL (CTEs, window functions, `DISTINCT ON`, `PERCENTILE_CONT`), Python, pandas, Streamlit, Altair,
Power BI

### Source code
[github.com/furqanahmed7890-gif/olist-ecommerce-analysis](https://github.com/furqanahmed7890-gif/olist-ecommerce-analysis)
""")

screenshot = Path(__file__).parent / "powerbi" / "screenshots" / "overview.png"
if screenshot.exists():
    st.markdown("### Power BI report")
    st.image(str(screenshot))
