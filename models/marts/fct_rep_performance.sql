-- Q5: WHO NEEDS COACHING?
-- Per-rep win rate, cycle time, and open pipeline. RANK() over the aggregate
-- ranks reps by won revenue in the same pass.
with d as (select * from {{ ref('int_deal_enriched') }})
select
    rep_id,
    rep_name,
    team,
    count(*)                                            as total_deals,
    sum(case when not is_closed then amount else 0 end) as open_pipeline,
    sum(case when is_won then 1 else 0 end)             as won_deals,
    round(100.0 * sum(case when is_won then 1 else 0 end)
          / nullif(sum(case when is_closed then 1 else 0 end), 0), 1) as win_rate_pct,
    round(avg(case when is_won then cycle_days end))    as avg_won_cycle_days,
    sum(case when is_won then amount else 0 end)        as won_revenue,
    rank() over (order by sum(case when is_won then amount else 0 end) desc) as revenue_rank
from d
group by rep_id, rep_name, team
order by won_revenue desc
