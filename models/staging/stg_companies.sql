-- Cleaned company dimension. Note how staging does the casting and adds a
-- simple business bucket (segment) so downstream models stay clean.
select
    company_id,
    company_name,
    industry,
    cast(employee_count as integer) as employee_count,
    country,
    case
        when cast(employee_count as integer) < 50  then 'SMB'
        when cast(employee_count as integer) < 250 then 'Mid-Market'
        else 'Enterprise'
    end as segment
from {{ ref('raw_companies') }}
