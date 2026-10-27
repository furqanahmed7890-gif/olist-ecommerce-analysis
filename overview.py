import altair as alt
import streamlit as st

from db import data_source, month_label, run_query, show_sql

st.title("Olist Marketplace: Why Customers Don't Come Back")
st.write(
    "99,441 orders from Olist, a Brazilian online marketplace, 2016-2018. Two questions: why don't customers "
    f"come back, and how much does late delivery hurt review scores? Every number here is a SQL query against "
    f"{data_source()}."
)

kpis = run_query("SELECT * FROM app_headline_kpis").iloc[0]
cols = st.columns(6)
cols[0].metric("Orders", f"{int(kpis['orders']):,}")
cols[1].metric("Customers", f"{int(kpis['customers']):,}")
cols[2].metric("Revenue", f"R${float(kpis['revenue']) / 1e6:.1f}M")
cols[3].metric("Ever came back", f"{float(kpis['returned_pct']):.1f}%", help="Ordered again on a later day")
cols[4].metric("Late deliveries", f"{float(kpis['late_pct']):.1f}%", help="Arrived after the promised date")
cols[5].metric("Review when late", f"{float(kpis['avg_review_late']):.2f}",
               delta=f"{float(kpis['avg_review_late']) - float(kpis['avg_review_on_time']):.2f} vs. on time")

left, right = st.columns(2)
left.info(
    "**Why don't customers come back?** Mostly because Olist is used for one-off purchases and nothing pulls "
    "customers back. Even after a perfect, on-time, 5-star first order only about 2% return within 180 days. "
    "What was bought matters more than how it went: home categories bring people back about 2.7x more often "
    "than gadgets."
)
right.info(
    f"**How much does late delivery hurt reviews?** A lot. Late orders average {float(kpis['avg_review_late']):.2f} "
    f"stars vs. {float(kpis['avg_review_on_time']):.2f} on time, and past a week late about 70% are 1-star. Late "
    f"orders are only {float(kpis['late_pct']):.1f}% of deliveries but {float(kpis['late_share_of_bad_reviews_pct']):.1f}% "
    "of all 1-2 star reviews."
)

monthly = run_query("SELECT * FROM app_monthly_kpis ORDER BY purchase_month")
monthly["month"] = month_label(monthly["purchase_month"])

left, right = st.columns(2)
with left:
    st.subheader("Revenue grew 8x, but almost every customer is new")
    base = alt.Chart(monthly).encode(x=alt.X("month:O", title="Month"))
    bars = base.mark_bar(color="#4682b4").encode(
        y=alt.Y("revenue:Q", title="Revenue (R$)"),
        tooltip=["month", alt.Tooltip("revenue:Q", format=",.0f"), "orders", "returning_pct"],
    )
    line = base.mark_line(color="#ff8c00", point=True).encode(
        y=alt.Y("returning_pct:Q", title="Customers who had bought before (%)", scale=alt.Scale(domain=[0, 10])),
    )
    st.altair_chart(alt.layer(bars, line).resolve_scale(y="independent"), width="stretch")
    st.caption("Bars: monthly revenue. Line: share of that month's customers who had ordered before (about 3%).")
    show_sql("monthly_kpis")

with right:
    st.subheader("When deliveries ran late, reviews dropped")
    base = alt.Chart(monthly).encode(x=alt.X("month:O", title="Month"))
    bars = base.mark_bar(color="#ff6347").encode(
        y=alt.Y("late_pct:Q", title="Late deliveries (%)"),
        tooltip=["month", "late_pct", "avg_review"],
    )
    line = base.mark_line(color="#2f4f4f", point=True).encode(
        y=alt.Y("avg_review:Q", title="Average review", scale=alt.Scale(domain=[3.5, 4.4])),
    )
    st.altair_chart(alt.layer(bars, line).resolve_scale(y="independent"), width="stretch")
    st.caption("Late deliveries spiked around Black Friday 2017 and in Feb-Mar 2018, and the average review fell in "
               "the same months.")
    show_sql("monthly_kpis")

st.subheader("Top categories by revenue")
categories = run_query("SELECT * FROM app_top_categories ORDER BY revenue DESC")
st.dataframe(
    categories,
    hide_index=True,
    width="stretch",
    column_config={
        "revenue": st.column_config.NumberColumn("revenue (R$)", format="localized"),
        "revenue_share_pct": st.column_config.ProgressColumn("share of revenue", format="%.1f%%", min_value=0, max_value=10),
    },
)
show_sql("top_categories")
