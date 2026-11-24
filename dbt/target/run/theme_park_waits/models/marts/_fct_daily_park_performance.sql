
  
    



create or replace transient  table DENG_ACCELERATOR.TABLES._fct_daily_park_performance
    
    
    
    
    as (with rides_daily as (
    SELECT *
    FROM DENG_ACCELERATOR.TABLES._int_daily_ride_wait
)

SELECT
park_id,
park_name,
park_local_date,
sum(total_valid_open_wait_minutes)
        / nullif(sum(valid_open_observation_count), 0)
        as avg_posted_wait_time_when_open,
sum(valid_open_observation_count) as valid_open_observation_count,
sum(total_observation_count) as total_observation_count
from rides_daily
GROUP BY park_id, park_name, park_local_date
    )
;



  