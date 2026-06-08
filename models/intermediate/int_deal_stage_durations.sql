-- *** This is the analytics-engineering heart of velocity analysis. ***
-- For each deal we order its stage history by date, then use LEAD() to look at
-- the NEXT stage's entry date. The gap is how long the deal sat in that stage.
-- If there is no next stage, the deal is still sitting there today.
with sequenced as (
    select
        deal_id,
        stage,
        entered_at,
        lead(entered_at) over (
            partition by deal_id
            order by entered_at
        ) as next_stage_entered_at
    from {{ ref('stg_deal_stage_history') }}
)
select
    deal_id,
    stage,
    entered_at,
    next_stage_entered_at,
    coalesce(next_stage_entered_at, current_date) - entered_at as days_in_stage,
    (next_stage_entered_at is null)                            as is_current_stage
from sequenced
