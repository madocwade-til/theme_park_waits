with rides_daily as (
    SELECT *
    FROM {{ref('_int_daily_ride_wait')}}
),

park_avg as (
    SELECT
    park_id,
    avg_posted_wait_time_when_open as daily_park_avg_wait,
    park_local_date
    FROM {{ref('_fct_daily_park_performance')}}
)

SELECT
    r.ride_id,
    a.park_id,
    a.park_local_date,
    r.avg_posted_wait_time_when_open as daily_ride_avg_wait,
    a.daily_park_avg_wait,
    ROUND(((daily_ride_avg_wait / nullif(a.daily_park_avg_wait, 0) - 1) * 100), 2)
    as relative_diff
FROM rides_daily r
LEFT JOIN park_avg a
ON r.park_id = a.park_id AND r.park_local_date = a.park_local_date