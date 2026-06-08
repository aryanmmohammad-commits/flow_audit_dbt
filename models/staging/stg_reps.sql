select
    rep_id,
    rep_name,
    team,
    cast(hire_date as date) as hire_date
from {{ ref('raw_reps') }}
