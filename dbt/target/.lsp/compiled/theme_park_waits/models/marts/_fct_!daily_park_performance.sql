with obs as (
    SELECT *
    FROM DENG_ACCELERATOR.TABLES._int_ride_parks
)


SELECT park_id, land_id, ride_id, AVG() FROM obs