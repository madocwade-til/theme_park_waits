with obs as (
    SELECT *
    FROM {{ref('_int_ride_parks')}}
),





SELECT park_id, land_id, ride_id, AVG() FROM 