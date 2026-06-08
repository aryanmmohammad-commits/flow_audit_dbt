-- Q2: WHERE DO DEALS STALL?
-- Average / median / max days per stage (open pipeline only), plus a count of
-- deals currently stuck in each stage for more than 30 days.
with dur as (select * from {{ ref('int_deal_stage_durations') }}),
stage_days as (
    select
        stage,
        count(*)                  as deals_entered,
        round(avg(days_in_stage), 1) as avg_days_in_stage,
        median(days_in_stage)     as median_days_in_stage,
        max(days_in_stage)        as max_days_in_stage
    from dur
    where stage not in ('Closed Won', 'Closed Lost')
    group by stage
),
stalled as (
    select stage, count(*) as stalled_open_deals
    from dur
    where is_current_stage
      and stage not in ('Closed Won', 'Closed Lost')
      and days_in_stage > 30
    group by stage
)
select
    s.stage,
    s.deals_entered,
    s.avg_days_in_stage,
    s.median_days_in_stage,
    s.max_days_in_stage,
    coalesce(st.stalled_open_deals, 0) as stalled_open_deals
from stage_days s
left join stalled st on s.stage = st.stage
order by s.avg_days_in_stage desc
