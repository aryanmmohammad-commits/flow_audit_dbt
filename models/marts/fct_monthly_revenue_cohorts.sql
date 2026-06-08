-- Bonus diagnostic: is revenue growing month over month, or stalling?
-- A "cohort" here = the month a deal was CREATED. We sum won revenue per
-- cohort month, then add a RUNNING (cumulative) total with a window function.
with monthly as (
    select
        date_trunc('month', created_at)              as cohort_month,
        count(*)                                      as deals_created,
        sum(case when is_won then 1 else 0 end)       as won_deals,
        sum(case when is_won then amount else 0 end)  as won_revenue
    from {{ ref('int_deal_enriched') }}
    group by date_trunc('month', created_at)
)
select
    cohort_month,
    deals_created,
    won_deals,
    won_revenue,
    -- the new skill: for each month, add this month + every earlier month
    sum(won_revenue) over (order by cohort_month) as running_total_won_revenue
from monthly
order by cohort_month