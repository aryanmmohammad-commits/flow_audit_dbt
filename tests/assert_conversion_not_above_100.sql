-- A funnel conversion can never exceed 100% of the top of the funnel.
-- If this query returns any rows, something is wrong with the funnel logic.
select stage, conversion_from_top_pct
from {{ ref('fct_funnel_conversion') }}
where conversion_from_top_pct > 100
