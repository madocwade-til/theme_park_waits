with obs_at as (
SELECT o.*, s.observed_at_utc
FROM DENG_ACCELERATOR.TABLES._stg_wait_observations o
LEFT JOIN DENG_ACCELERATOR.TABLES._stg_snapshots s
ON o.snapshot_id = s.snapshot_id
),

ride_timezones as (
    SELECT o.*, 
    p.timezone, 
    convert_timezone('UTC', p.timezone, o.observed_at_utc)::date as park_local_date
    FROM obs_at o
    LEFT JOIN DENG_ACCELERATOR.TABLES._stg_parks p 
    ON o.park_id = p.park_id
)

SELECT * from ride_timezones