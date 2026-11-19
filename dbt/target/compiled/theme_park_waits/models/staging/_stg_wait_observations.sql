

SELECT
snapshot_id,
ride_id,
ride_name,
land_id as park_id,
land_name as park_name,
is_open,
reported_wait_minutes,
source_updated_at_utc

FROM `deng_accelerator`.`raw_data`.`wait_observations`