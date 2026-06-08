# Flow Audit — a CRM-agnostic revenue-flow diagnostic

A B2B **Revenue Operations** diagnostic, built as a production-style **analytics-engineering**
pipeline. It takes CRM-style data (leads, deals, companies, activities), transforms it through
clean, tested, documented `dbt` models, and produces six diagnostics that pinpoint **where
revenue leaks through a sales funnel** — ready to feed a Power BI dashboard.

The same six models work on any company's data: only the staging layer is adapted per source,
so the diagnostic engine is reusable across CRMs.

**Stack:** dbt Core · DuckDB · SQL (CTEs + window functions) · Power BI — runs locally at zero cost.

---

## The six diagnostics

Each model targets one specific obstruction in the revenue flow. The example findings below come
from the included **synthetic dataset**, which has realistic problems deliberately built in:

| Model | Question it answers | Example finding (synthetic data) |
|---|---|---|
| `fct_funnel_conversion` | Where is the funnel leaking? | A steep qualified-stage drop; only 15% of opportunities close won |
| `fct_pipeline_velocity` | Where do deals stall? | Deals pile up in Proposal — 31 stuck more than 30 days |
| `fct_win_loss` | How well do we close, by segment? | Win rate and cycle time broken down per company segment |
| `fct_channel_performance` | Which channels make money vs noise? | Referral = €3,936 per lead, while Paid Search + Trade Show = 774 leads and €0 won |
| `fct_rep_performance` | Who needs coaching? | Team B: 25% win rate, 86-day cycle vs Team A: 35%, 49 days |
| `fct_revenue_health` | Is revenue healthy or fragile? | Top 5 deals = 47% of won revenue (concentration risk) |

---

## Architecture

The core analytics-engineering pattern — data flows one direction, getting cleaner and more
business-ready at each layer:

```
seeds/ (raw CSVs)            raw data, exactly as a CRM would export it
        |
        v
models/staging/             one model per source: cast types, rename, light cleaning  (views)
        |
        v
models/intermediate/        joins + reusable logic, e.g. window functions  (views)
        |
        v
models/marts/               the six business answers — clean tables a dashboard reads  (tables)
```

- **Staging** does all type casting; raw data stays as text.
- **Intermediate** holds the analytical SQL — `int_deal_stage_durations.sql` uses a `LEAD()`
  window function to measure how long each deal sat in each stage (the basis of velocity analysis).
- **Marts** are the deliverable: each `fct_*` model answers one diagnostic question.

Data quality is enforced with dbt tests (uniqueness, not-null, relationships, accepted values),
and the project ships with a clean `dbt build` of `PASS=40, ERROR=0`.

---

## Run it

```bash
pip install dbt-core dbt-duckdb
dbt build --profiles-dir .
```

`dbt build` loads the seed data, builds the staging -> intermediate -> marts models, and runs every
test, in dependency order. To explore the model lineage graph:

```bash
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```

---

## Roadmap

Planned extensions, in order of priority:

1. Swap the synthetic seeds for live CRM data, converting raw tables to dbt `sources`.
2. Split pipeline velocity into completed-transition time vs current-dwell time.
3. A monthly revenue-cohort model with a running total (`SUM() OVER (ORDER BY month)`).
4. Incremental materialization for the fact models.
5. dbt snapshots to track deal stage changes as a slowly-changing dimension.
6. `dbt_utils` data-contract tests; migration to a cloud warehouse (BigQuery) with scheduled refresh.

---

## Connecting to Power BI

The marts are shaped as clean fact tables, so they drop straight into a Power BI model. Export the
marts to Excel (a small helper script does this), then point Power BI at the file — or, for a
cloud version, repoint the dbt profile from DuckDB to BigQuery and use Power BI's native connector.
