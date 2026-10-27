import streamlit as st

st.set_page_config(page_title="Olist Customers & Delivery", page_icon="📦", layout="wide")

page = st.navigation([
    st.Page("overview.py", title="Overview", icon="📊"),
    st.Page("retention.py", title="Retention", icon="🔁"),
    st.Page("delivery.py", title="Delivery & Reviews", icon="🚚"),
    st.Page("segments.py", title="Customer Segments", icon="👥"),
    st.Page("about.py", title="About", icon="ℹ️"),
])

page.run()
