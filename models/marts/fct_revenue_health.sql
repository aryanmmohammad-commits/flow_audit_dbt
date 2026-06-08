-- Q6: IS THE REVENUE HEALTHY OR FRAGILE?
-- A single snapshot: pipeline coverage and how concentrated won revenue is in
-- the top 5 deals (high concentration = fragile forecast).
with d as (select * from {{ ref('int_deal_enriched') }}),
won as (select * from d where is_won),
open_deals as (select * from d where not is_closed),
ranked as (
    select amount,
           row_number() over (order by amount desc) as rn,
           sum(amount) over ()                      as total_won
    from won
)
select
    (select count(*)   from won)                                                    as won_deals,
    (select sum(amount) from won)                                                   as won_revenue,
    (select sum(amount) from open_deals)                                            as open_pipeline,
    round((select sum(amount) from open_deals) * 1.0
          / nullif((select sum(amount) from won), 0), 2)                            as pipeline_coverage_ratio,
    round((select sum(amount) from won) * 1.0
          / nullif((select count(*) from won), 0))                                  as avg_won_deal_size,
    round(100.0 * (select sum(amount) from ranked where rn <= 5)
          / nullif((select max(total_won) from ranked), 0), 1)                      as top5_revenue_concentration_pct
