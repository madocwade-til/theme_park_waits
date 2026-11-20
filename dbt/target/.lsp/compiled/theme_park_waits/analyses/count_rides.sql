with stg_count as (
    SELECT 
    COUNT(DISTINCT ride_id) as stg_count
    FROM `deng_accelerator`.`output`.`_stg_wait_observations`
),

int_count as (
    SELECT 
    COUNT(DISTINCT ride_id) as int_count
    FROM `deng_accelerator`.`output`.`_int_wait_by_ride`
)

SELECT
s.stg_count,
i.int_count,
stg_count - int_count as count_diff
FROM stg_count s
CROSS JOIN int_count i