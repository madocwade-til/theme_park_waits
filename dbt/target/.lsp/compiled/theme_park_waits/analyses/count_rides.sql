with stg_count as (
    SELECT 
    COUNT(DISTINCT ride_id) as stg_count
    FROM DENG_ACCELERATOR.TABLES._stg_wait_observations
),

int_count as (
    SELECT 
    COUNT(DISTINCT ride_id) as int_count
    FROM DENG_ACCELERATOR.TABLES._int_ride_parks
)

SELECT
s.stg_count,
i.int_count,
stg_count - int_count as count_diff
FROM stg_count s
CROSS JOIN int_count i