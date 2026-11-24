

SELECT
snapshot_id,
ride_id,
ride_name,
land_id,
land_name,
is_open,
reported_wait_minutes,
source_updated_at_utc

FROM {{source('wait_times', 'wait_observations')}}
