select
    activity_id,
    deal_id,
    activity_type,
    cast(activity_at as date) as activity_at
from {{ ref('raw_activities') }}
