-- Q1: WHERE IS THE FUNNEL LEAKING?
-- Counts at each stage, then uses window functions to compute conversion from
-- the previous stage and from the top. The smallest "from previous" % is the leak.
with counts as (
    select 1 as step_order, 'Leads'       as stage, (select count(*) from {{ ref('stg_leads') }})                  as records
    union all
    select 2,               'MQL',        (select count(*) from {{ ref('stg_leads') }} where is_mql)
    union all
    select 3,               'SQL',        (select count(*) from {{ ref('stg_leads') }} where is_sql)
    union all
    select 4,               'Opportunity',(select count(*) from {{ ref('stg_deals') }})
    union all
    select 5,               'Closed Won', (select count(*) from {{ ref('stg_deals') }} where is_won)
)
select
    step_order,
    stage,
    records,
    round(100.0 * records / nullif(lag(records)         over (order by step_order), 0), 1) as conversion_from_previous_pct,
    round(100.0 * records / nullif(first_value(records) over (order by step_order), 0), 1) as conversion_from_top_pct
from counts
order by step_order
