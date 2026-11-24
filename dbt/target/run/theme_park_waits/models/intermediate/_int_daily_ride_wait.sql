
  create or replace   view DENG_ACCELERATOR.TABLES._int_daily_ride_wait
  
  
  
  
  as (
    --calculating the average wait time per ride per day

with wait_times as (
    select
        park_id,
        park_name,
        ride_id,
        ride_name,
        cast(park_local_time as date) as park_local_date,
        case
            when is_open and reported_wait_time >= 0
            then reported_wait_time
        end as valid_open_wait_minutes
    from DENG_ACCELERATOR.TABLES._int_ride_parks
)

select
    park_id,
    park_name,
    ride_id,
    ride_name,
    park_local_date,
    avg(valid_open_wait_minutes) as avg_posted_wait_time_when_open,
    sum(valid_open_wait_minutes) as total_valid_open_wait_minutes,
    count(valid_open_wait_minutes) as valid_open_observation_count,
    count(*) as total_observation_count
from wait_times
group by park_id, park_name, ride_id, ride_name, park_local_date
  );

