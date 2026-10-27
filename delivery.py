import altair as alt
import streamlit as st

from db import run_query, show_sql

st.title("How Much Does Late Delivery Hurt Reviews?")

kpis = run_query("SELECT * FROM app_headline_kpis").iloc[0]
cols = st.columns(4)
cols[0].metric("Deliveries that were late", f"{float(kpis['late_pct']):.1f}%")
cols[1].metric("Average review, on time", f"{float(kpis['avg_review_on_time']):.2f}")
cols[2].metric("Average review, late", f"{float(kpis['avg_review_late']):.2f}",
               delta=f"{float(kpis['avg_review_late']) - float(kpis['avg_review_on_time']):.2f}")
cols[3].metric("Share of 1-2 star reviews from late orders", f"{float(kpis['late_share_of_bad_reviews_pct']):.1f}%")

st.subheader("Reviews collapse once an order misses its promised date")
delay = run_query("SELECT * FROM app_review_by_delay ORDER BY delivery_vs_promise")
delay["bucket"] = delay["delivery_vs_promise"].str[4:]
delay["timing"] = delay["delivery_vs_promise"].str.contains("late").map({True: "Late", False: "On time or early"})
order = delay["bucket"].tolist()
bars = alt.Chart(delay).mark_bar().encode(
    x=alt.X("bucket:N", sort=order, title="Delivery vs. promised date"),
    y=alt.Y("avg_review:Q", title="Average review", scale=alt.Scale(domain=[0, 5])),
    color=alt.Color("timing:N", scale=alt.Scale(domain=["On time or early", "Late"], range=["#4682b4", "#ff6347"]),
                    title=None),
    tooltip=["bucket", "orders", "avg_review", "one_star_pct", "five_star_pct"],
)
text = bars.mark_text(dy=-8).encode(text=alt.Text("avg_review:Q", format=".2f"), color=alt.value("gray"))
st.altair_chart(bars + text, width="stretch")
st.write(
    "Early orders all score about the same (4.2-4.3). The drop starts the day the promise is missed: 1-3 days late "
    "averages 3.29 with 25% one-star reviews, and past a week late about 70% of reviews are 1-star."
)
show_sql("review_by_delay")

left, right = st.columns(2)
with left:
    st.subheader("Customers judge the promise, not the wait")
    promise = run_query("SELECT * FROM app_wait_vs_promise ORDER BY actual_wait, vs_promise")
    promise["wait"] = promise["actual_wait"].str[3:]
    chart = alt.Chart(promise).mark_bar().encode(
        x=alt.X("wait:N", sort=promise["wait"].unique().tolist(), title="Actual wait"),
        xOffset="vs_promise:N",
        y=alt.Y("avg_review:Q", title="Average review", scale=alt.Scale(domain=[0, 5])),
        color=alt.Color("vs_promise:N", scale=alt.Scale(domain=["On time", "Late"], range=["#4682b4", "#ff6347"]),
                        title=None),
        tooltip=["wait", "vs_promise", "orders", "avg_review"],
    )
    st.altair_chart(chart, width="stretch")
    st.write(
        "For the same 7-13 day wait, on-time orders average 4.32 and late ones 3.36. A 30+ day order that arrived on "
        "time scores better than a late order that took 21-29 days. Generous delivery estimates are doing their job."
    )
    show_sql("wait_vs_promise")

with right:
    st.subheader("Where lateness happens")
    states = run_query("SELECT * FROM app_late_by_state ORDER BY late_pct DESC")
    chart = alt.Chart(states).mark_bar(color="#ff6347").encode(
        x=alt.X("customer_state:N", sort="-y", title="Customer state"),
        y=alt.Y("late_pct:Q", title="Late deliveries (%)"),
        tooltip=["customer_state", "delivered_orders", "late_pct", "avg_delivery_days", "avg_review"],
    )
    st.altair_chart(chart, width="stretch")
    st.write(
        "North-eastern states are let down most often (Alagoas 21% late, Maranhão 17%) vs. São Paulo at 4.5%. "
        "Rio de Janeiro stands out among the big states at 12%."
    )
    show_sql("late_by_state")

st.info(
    "**What to do:** keep promises rather than chase speed. Pad delivery estimates more for north-eastern states "
    "and Rio, and flag the small group of sellers that are late more than 15% of the time (they average 3.66 stars "
    "vs. 4.28 for reliable sellers)."
)
