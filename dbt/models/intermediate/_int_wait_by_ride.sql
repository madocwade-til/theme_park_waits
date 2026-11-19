with wait_times as (
    SELECT *
    FROM {{ref('_stg_wait_observations')}}
),

avg_by_ride as (
    SELECT AVG(reported_wait_minutes) as avg_wait,
    ride_id,
    ride_name,
    park_id,
    park_name
    FROM wait_times
    GROUP BY ride_id, ride_name, park_id, park_name
    ORDER BY avg_wait desc
)

SELECT *
FROM avg_by_ride