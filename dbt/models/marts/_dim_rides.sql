with rides as (
    SELECT ride_id, ride_name, park_id, park_name
    FROM {{ref('_stg_wait_observations')}}
    WHERE NOT isnull(park_id)
    GROUP BY ride_id, ride_name, park_id, park_name
    ORDER BY park_id asc, ride_id asc
)

SELECT *
FROM rides