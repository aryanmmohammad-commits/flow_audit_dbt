# Flow Audit — a RevOps revenue-flow diagnostic, built as an analytics-engineering pipeline

This is the Flow Audit rebuilt the way an **analytics engineer** builds things: raw data
transformed through clean, tested, documented `dbt` models running on a data warehouse.
It is your portfolio piece **and** your product in one artifact. The whole thing runs
locally at zero cost on `dbt Core` + `DuckDB`.

The point of this repo is not to read it. It is to **run it, understand each layer, then
extend it** — that is how the skill goes in. Everything below is built to be modified.

---

## Run it (3 commands)

```bash
pip install dbt-core dbt-duckdb --break-system-packages
export DBT_PROFILES_DIR=$(pwd)          # tells dbt to read the profiles.yml in this folder
dbt build                                # seeds the data, builds every model, runs every test
```

Then see the **lineage graph** — the visual that says "production thinking" at a glance:

```bash
dbt docs generate
dbt docs serve                           # opens an interactive site; click "lineage" bottom-right
```

`dbt build` does three things in dependency order: loads the CSVs as `seeds`, builds the
`staging → intermediate → marts` models, and runs all data-quality `tests`. A green
`PASS=40 ERROR=0` means the pipeline is sound end to end.

---

## How it is layered

This is the core analytics-engineering pattern. Data flows **one direction**, getting
cleaner and more business-ready at each step:

```
seeds/ (raw CSVs)            <- raw data, exactly as a CRM would dump it
   |
   v
models/staging/             <- 1 model per source: cast types, rename, light cleaning. Views.
   |
   v
models/intermediate/        <- joins + reusable logic (e.g. window functions). Views.
   |
   v
models/marts/               <- the 6 business answers. Tables a dashboard reads directly.
```

- **Staging is where casting happens.** Raw stays as text; `stg_*` models do the work.
  Look at `stg_leads.sql` to see the empty-string-to-date handling.
- **Intermediate is the clever bit.** `int_deal_stage_durations.sql` uses a `LEAD()` window
  function to measure how long each deal sat in each stage — this is the analytical SQL
  that powers velocity analysis, and exactly the frontier you are building toward.
- **Marts are the deliverable.** Each `fct_*` model answers one diagnostic question and is
  a clean table your Power BI dashboard points at.

---

## The six diagnostics (your engine)

Each one hunts a specific obstruction in the revenue flow:

| Model | Question it answers | What it found in the demo data |
|---|---|---|
| `fct_funnel_conversion` | Where is the funnel leaking? | Steep qualified-stage drop; only 15% of opportunities close won |
| `fct_pipeline_velocity` | Where do deals stall? | Deals pile up in **Proposal** — 31 stuck >30 days |
| `fct_win_loss` | How well do we close, by segment? | Win rate and cycle time per company segment |
| `fct_channel_performance` | Which channels make money vs noise? | **Referral = €3,936/lead; Paid Search + Trade Show = 774 leads, €0 won** |
| `fct_rep_performance` | Who needs coaching? | **Team B: 25% win, 86-day cycle** vs Team A: 35%, 49 days |
| `fct_revenue_health` | Is revenue healthy or fragile? | Top 5 deals = **47%** of won revenue (concentration risk) |

The synthetic dataset has these problems deliberately baked in so the diagnostics have
something real to find. When you swap in your own data, the same six models do the work.

---

## *** YOUR TURN *** (this is the learning)

Do these in order. Each one teaches a real analytics-engineering concept by building it.

1. **Swap in real data.** Replace the CSVs in `seeds/` with an export from your own CRM
   (HubSpot/Pipedrive), keeping the column names. For the production pattern, convert the
   raw tables to dbt `sources`: add a `_sources.yml`, then change `ref('raw_leads')` to
   `source('crm', 'leads')` in the staging models. *Concept: sources vs seeds.*

2. **Fix the velocity model.** Right now `avg_days_in_stage` mixes two different things:
   time deals *spent* in a stage (completed) and time open deals have *been sitting* there.
   Split them into two columns: `avg_completed_transition_days` and `avg_current_dwell_days`.
   *Concept: thinking precisely about what a metric means.*

3. **Add a cohort model with a running total.** Build `fct_monthly_revenue_cohorts.sql`:
   won revenue by the month a deal was created, with a `SUM() OVER (ORDER BY month)`
   cumulative total. *Concept: window functions for time-series — your SQL frontier.*

4. **Make a mart incremental.** Add `{{ config(materialized='incremental') }}` to a fact
   model and an `is_incremental()` filter so it only processes new rows on each run.
   *Concept: incremental models — the thing that makes pipelines scale.*

5. **Track stage changes over time with a snapshot.** Add a dbt `snapshot` on deals so you
   capture stage history as a slowly-changing dimension. *Concept: snapshots / SCD.*

6. **Add the `dbt_utils` package and more tests.** Create `packages.yml`, run `dbt deps`,
   then use `dbt_utils.accepted_range` to assert `win_rate_pct` is between 0 and 100.
   *Concept: packages + stronger data contracts.*

When 1–3 are done, you have a genuinely strong portfolio repo. Push it to GitHub with this
README, link the lineage graph screenshot, and that link is your leverage in an interview.

---

## Connect to Power BI (closing the loop)

Your existing Power BI work sits on top of these marts — nothing wasted:

- **Quick path:** export the marts to CSV (`dbt run`, then query the `.duckdb` file) and
  load them into Power BI.
- **Live path:** Power BI connects to DuckDB via ODBC, or — for the cloud-flavored
  portfolio version — repoint `profiles.yml` from `type: duckdb` to BigQuery (free sandbox)
  and connect Power BI's native BigQuery connector to the `marts` dataset.

The marts are deliberately shaped as clean fact tables, so they drop straight into a
Power BI model with no further wrangling.

---

— By Aryan Mohammaddoost. Wishing you clarity and sustained focus.
