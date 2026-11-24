select
    park_id,
    name as park_name,
    timezone as park_timezone,
    country,
    group_name,
    latitude,
    longitude
from {{ ref('_stg_parks') }}