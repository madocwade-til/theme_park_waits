--calculating the average wait time per ride

with wait_times as (
    SELECT *
    FROM DENG_ACCELERATOR.TABLES._stg_wait_observations
)

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
from wait_times
group by land_id, ride_id