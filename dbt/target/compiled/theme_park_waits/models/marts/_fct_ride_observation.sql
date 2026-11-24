select
    park_id,
    ride_id,
    park_local_date,
    avg(
        case
            when is_open and reported_wait_minutes >= 0
            then reported_wait_minutes
        end
    ) as avg_posted_wait_minutes_when_open,
    count(
        case when is_open and reported_wait_minutes >= 0 then 1 end
    ) as valid_open_observation_count,
    count(*) as total_observation_count
from DENG_ACCELERATOR.TABLES._stg_wait_observations
group by park_id, ride_id, park_local_date