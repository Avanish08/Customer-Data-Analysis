# Customer Data Analysis — Findings

**Dataset:** 800 customers, 8980 cleaned transactions (from 9025 raw rows,
after removing duplicates and null amounts).

## Key Insights
- **Top revenue segment:** Consumer ($561,320 across 5719 transactions).
- **Top city by revenue:** Mumbai ($163,971).
- **240 customers** qualify as "Champions" (frequent, recent, high-spend) under the RFM segmentation — these are the retention priority.
- **60 customers** are flagged "At Risk" (no purchase in 300+ days) — a clear re-engagement target list (see RFM query output).
- **23 customers never made a single transaction** after signing up — an onboarding/activation gap worth investigating.
- Revenue is concentrated in **Subscription** and **One-time Purchase** categories; Refunds are a small (~5%) drag on net revenue.

## Data Cleaning Performed
- Standardized city names (trimmed whitespace, fixed inconsistent casing e.g. "  mumbai " → "Mumbai").
- Removed 45 duplicate/null-amount transaction rows.
- Replaced missing city values with an explicit "Unknown" category rather than dropping rows.

## Files
- `customer_data.db` — SQLite database (raw + cleaned views)
- `queries.sql` — all SQL used for this analysis, runnable standalone
- `analysis.py` — this script (cleaning, EDA, chart generation)
- `charts/` — 5 exploratory charts
