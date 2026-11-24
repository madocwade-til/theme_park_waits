select
    park_id,
    ride_id,
    ride_name,
    land_id,
    land_name
from DENG_ACCELERATOR.TABLES._int_ride_parks
where park_id is not null
  and ride_id is not null
qualify row_number() over (
    partition by park_id, ride_id
    order by observed_at_utc desc nulls last, snapshot_id desc
) = 1