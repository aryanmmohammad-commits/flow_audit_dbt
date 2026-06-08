-- Q3: HOW WELL DO WE CLOSE, AND DOES IT DIFFER BY SEGMENT?
-- ROLLUP gives a per-segment breakdown plus an overall row (segment = null).
with d as (select * from {{ ref('int_deal_enriched') }} where is_closed)
select
    segment,
    count(*)                                                       as closed_deals,
    sum(case when is_won then 1 else 0 end)                        as won_deals,
    sum(case when not is_won then 1 else 0 end)                    as lost_deals,
    round(100.0 * sum(case when is_won then 1 else 0 end) / count(*), 1) as win_rate_pct,
    round(avg(case when is_won then amount end))                   as avg_won_deal_size,
    round(avg(cycle_days))                                         as avg_cycle_days
from d
group by rollup (segment)
order by segment nulls last
