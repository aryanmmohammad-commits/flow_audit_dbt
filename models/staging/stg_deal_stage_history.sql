-- One row per stage a deal has entered, with the date it entered.
select
    history_id,
    deal_id,
    stage,
    cast(entered_at as date) as entered_at
from {{ ref('raw_deal_stage_history') }}
