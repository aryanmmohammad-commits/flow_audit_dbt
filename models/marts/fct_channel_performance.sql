-- Q4: WHICH CHANNELS PRODUCE REVENUE vs JUST VOLUME?
-- This is the vanity-metric detector: revenue_per_lead exposes channels that
-- look busy (lots of leads) but rarely turn into money.
with lead_counts as (
    select lead_source,
           count(*)                                as leads,
           sum(case when is_sql then 1 else 0 end) as sqls
    from {{ ref('stg_leads') }}
    group by lead_source
),
deal_outcomes as (
    select lead_source,
           count(*)                                  as opportunities,
           sum(case when is_won then 1 else 0 end)    as won_deals,
           sum(case when is_won then amount else 0 end) as won_revenue
    from {{ ref('int_deal_enriched') }}
    group by lead_source
)
select
    lc.lead_source,
    lc.leads,
    lc.sqls,
    coalesce(dl.opportunities, 0) as opportunities,
    coalesce(dl.won_deals, 0)     as won_deals,
    coalesce(dl.won_revenue, 0)   as won_revenue,
    round(100.0 * coalesce(dl.won_deals, 0) / nullif(dl.opportunities, 0), 1) as win_rate_pct,
    round(coalesce(dl.won_revenue, 0) * 1.0 / nullif(lc.leads, 0))            as revenue_per_lead
from lead_counts lc
left join deal_outcomes dl on lc.lead_source = dl.lead_source
order by won_revenue desc
