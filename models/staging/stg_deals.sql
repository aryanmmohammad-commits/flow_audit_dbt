-- The sales funnel. A deal is created when an SQL converts to an opportunity.
select
    deal_id,
    company_id,
    lead_id,
    owner_id                          as rep_id,
    cast(amount as integer)           as amount,
    cast(created_at as date)          as created_at,
    current_stage,
    (cast(is_closed as integer) = 1)  as is_closed,
    (cast(is_won as integer) = 1)     as is_won,
    nullif(closed_at, '')::date       as closed_at
from {{ ref('raw_deals') }}
