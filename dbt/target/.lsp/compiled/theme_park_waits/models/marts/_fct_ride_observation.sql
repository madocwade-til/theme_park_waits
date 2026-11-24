select
    park_id,
    ride_id,
    ride_name,
    land_id,
    land_name,
    park_local_date,
    avg(
        case
            when is_open and reported_wait_minutes >= 0 --we want the average wait minutes, but only those rows when the ride is open
            then reported_wait_minutes
        end
    ) as avg_posted_wait_minutes_when_open,
    count(
        case when is_open and reported_wait_minutes >= 0 then 1 end
    ) as valid_open_observation_count,
    count(*) as total_observation_count
from DENG_ACCELERATOR.TABLES._int_ride_parks
group by park_id, ride_id, park_local_date