import altair as alt
import pandas as pd
import streamlit as st

from db import run_query, show_sql

st.title("Customer Segments (RFM)")
st.write(
    "Every customer scored on **Recency** (days since last order), **Frequency** (did they come back?) and "
    "**Monetary** value (total spend). `NTILE(5)` window functions split customers into fifths on recency and spend."
)

segments = run_query("SELECT * FROM app_rfm_summary ORDER BY segment")
segments["name"] = segments["segment"].str[3:]

long = segments.melt(id_vars="name", value_vars=["pct_of_customers", "pct_of_revenue"], var_name="measure", value_name="pct")
long["measure"] = long["measure"].map({"pct_of_customers": "% of customers", "pct_of_revenue": "% of revenue"})
chart = alt.Chart(long).mark_bar().encode(
    x=alt.X("name:N", sort=segments["name"].tolist(), title=None),
    xOffset="measure:N",
    y=alt.Y("pct:Q", title="%"),
    color=alt.Color("measure:N", scale=alt.Scale(range=["#4682b4", "#ff8c00"]), title=None),
    tooltip=["name", "measure", "pct"],
)
st.altair_chart(chart, width="stretch")

st.dataframe(
    segments.drop(columns=["name"]),
    hide_index=True,
    width="stretch",
    column_config={"revenue": st.column_config.NumberColumn("revenue (R$)", format="localized")},
)
show_sql("rfm_segments", "rfm_summary")

st.subheader("What to do with each segment")
st.write(
    "Only 2% of customers have ever come back. The biggest opportunity is **New big spenders**: 15.5% of customers "
    "but 28.4% of revenue, recent, and mostly happy with their first order."
)
st.table(pd.DataFrame({
    "Segment": ["Loyal / Repeat, going quiet", "New big spender", "New", "Cooling off", "Lost / Lost big spender"],
    "Action": [
        "Thank-you perks; ask for reviews and referrals",
        "Second-order offer 2-3 months after the first purchase, in the same category",
        "Low-cost welcome series; cross-sell replenishable home categories",
        "Service recovery if the first order was late or poorly rated, then an offer",
        "One low-cost win-back attempt, then stop spending on them",
    ],
}).set_index("Segment"))
