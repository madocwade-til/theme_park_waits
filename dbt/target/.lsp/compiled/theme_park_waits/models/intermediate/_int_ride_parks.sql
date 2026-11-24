-- joining parks to ride observation data


with wait_observations as (
SELECT *
FROM DENG_ACCELERATOR.TABLES._stg_wait_observations
),

snapshots as (
    SELECT *
    FROM DENG_ACCELERATOR.TABLES._stg_snapshots
),

parks as (
    SELECT *
    FROM DENG_ACCELERATOR.TABLES._stg_parks
)

select
    w.snapshot_id,
    w.ride_id,
    w.ride_name,
    w.is_open,
    w.land_id,
    w.land_name,
    s.park_id,
    p.name as park_name,
    w.reported_wait_minutes as reported_wait_time,
    s.observed_at_utc,
    convert_timezone('UTC', p.timezone, s.observed_at_utc)::datetime as park_local_time
from wait_observations as w
left join snapshots as s
    on w.snapshot_id = s.snapshot_id
left join parks as p
    on s.park_id = p.park_id