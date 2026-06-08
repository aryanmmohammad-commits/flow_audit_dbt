-- One enriched row per deal: the deal joined to its company, rep, and source,
-- plus the cycle time for closed deals. Marts build on this instead of
-- re-joining the same tables over and over.
with deals as (select * from {{ ref('stg_deals') }})
select
    d.deal_id,
    d.company_id,
    c.company_name,
    c.industry,
    c.segment,
    c.country,
    d.rep_id,
    r.rep_name,
    r.team,
    l.lead_source,
    d.amount,
    d.created_at,
    d.current_stage,
    d.is_closed,
    d.is_won,
    d.closed_at,
    case when d.is_closed then d.closed_at - d.created_at end as cycle_days
from deals d
left join {{ ref('stg_companies') }} c on d.company_id = c.company_id
left join {{ ref('stg_reps') }}      r on d.rep_id     = r.rep_id
left join {{ ref('stg_leads') }}     l on d.lead_id    = l.lead_id
