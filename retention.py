import altair as alt
import streamlit as st

from db import month_label, run_query, show_sql

st.title("Why Don't Customers Come Back?")

timing = run_query("SELECT * FROM app_time_to_return").iloc[0]
kpis = run_query("SELECT * FROM app_headline_kpis").iloc[0]
curve = run_query("""
SELECT
    month_number,
    ROUND(SUM(active_customers) * 100.0 / SUM(cohort_customers), 2) AS avg_retention_pct
FROM app_cohort_retention
WHERE month_number BETWEEN 1 AND 12
GROUP BY month_number
ORDER BY month_number
""")

cols = st.columns(4)
cols[0].metric("Customers who ever came back", f"{float(kpis['returned_pct']):.1f}%")
cols[1].metric("Ordered again the next month", f"{float(curve['avg_retention_pct'].iloc[0]):.2f}%",
               help="Average month-1 retention across cohorts")
cols[2].metric("Median time to come back", f"{float(timing['median_days']):.0f} days",
               help="Among customers who did return")
cols[3].metric("Returners back within 90 days", f"{float(timing['within_90d_pct']):.0f}%")

st.subheader("Cohort retention: share of each month's new customers who ordered again")
cohorts = run_query("""
SELECT cohort_month, cohort_customers, month_number, retention_pct
FROM app_cohort_retention
WHERE month_number BETWEEN 1 AND 12
ORDER BY cohort_month, month_number
""")
cohorts["cohort"] = month_label(cohorts["cohort_month"])
heatmap = alt.Chart(cohorts).mark_rect().encode(
    x=alt.X("month_number:O", title="Months since first order"),
    y=alt.Y("cohort:O", title="First-order month"),
    color=alt.Color("retention_pct:Q", title="% of cohort", scale=alt.Scale(scheme="blues", domain=[0, 1])),
    tooltip=["cohort", "cohort_customers", "month_number", "retention_pct"],
)
labels = alt.Chart(cohorts).mark_text(fontSize=10).encode(
    x="month_number:O", y="cohort:O", text=alt.Text("retention_pct:Q", format=".2f"),
)
st.altair_chart(heatmap + labels, width="stretch")
st.write(
    "Retention never builds. About 0.5% of each cohort orders again the month after their first purchase, and "
    "0.2-0.3% in each month after that. No cohort ever passes 0.71% in a single month."
)
show_sql("first_orders", "cohort_retention")

st.subheader("What about the first order predicts a return?")
st.write(
    "180-day return rate by what happened on the customer's first order, with 95% confidence intervals. Only "
    "first orders from Jan 2017 to Feb 2018 count, so every customer had a full 180 days to come back."
)
dimensions = run_query("SELECT DISTINCT dimension FROM app_return_drivers ORDER BY dimension")["dimension"].tolist()
default = dimensions.index("First order category") if "First order category" in dimensions else 0
dimension = st.selectbox("Split first orders by", dimensions, index=default)
drivers = run_query(
    "SELECT * FROM app_return_drivers WHERE dimension = :dimension ORDER BY return_180d_pct DESC",
    {"dimension": dimension},
)
drivers["low"] = drivers["return_180d_pct"] - drivers["ci95_pct"]
drivers["high"] = drivers["return_180d_pct"] + drivers["ci95_pct"]
order = drivers["value"].tolist()
bars = alt.Chart(drivers).mark_bar(color="#4682b4").encode(
    x=alt.X("value:N", sort=order, title=None),
    y=alt.Y("return_180d_pct:Q", title="Came back within 180 days (%)"),
    tooltip=["value", "customers", "return_180d_pct", "ci95_pct"],
)
errors = alt.Chart(drivers).mark_errorbar().encode(
    x=alt.X("value:N", sort=order), y=alt.Y("low:Q", title="Came back within 180 days (%)"), y2="high:Q",
)
baseline = alt.Chart().mark_rule(color="gray", strokeDash=[4, 4]).encode(y=alt.datum(1.99))
st.altair_chart(alt.layer(bars, errors, baseline, data=drivers), width="stretch")
st.caption("Dashed line: all eligible customers (1.99%). Groups with fewer than 1,000 customers are hidden.")

st.write(
    "**What was bought matters more than how it went.** Home categories (bed/bath/table, sports & leisure, "
    "furniture) bring customers back about 2.7x more often than one-off purchases like \"cool stuff\" or computer "
    "accessories. A late first delivery or a 1-2 star first review lowers the return rate by about 20%, but even "
    "customers with a perfect first order rarely come back."
)
show_sql("return_drivers")
