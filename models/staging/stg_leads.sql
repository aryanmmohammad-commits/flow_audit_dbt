-- The demand funnel lives here. We turn the "reached this stage" timestamps
-- into clean dates plus boolean flags the funnel mart can count directly.
select
    lead_id,
    company_id,
    lead_source,
    campaign,
    cast(created_at as date)        as created_at,
    nullif(mql_at, '')::date        as became_mql_at,
    nullif(sql_at, '')::date        as became_sql_at,
    (nullif(mql_at, '') is not null) as is_mql,
    (nullif(sql_at, '') is not null) as is_sql
from {{ ref('raw_leads') }}
