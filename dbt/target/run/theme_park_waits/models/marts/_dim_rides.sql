
  
    
        create or replace table `deng_accelerator`.`output`.`_dim_rides`
      
      
    
      using delta
    
  
      
      
      
      
      
      
      
      
      as
      with rides as (
    SELECT ride_id, ride_name, park_id, park_name
    FROM `deng_accelerator`.`output`.`_stg_wait_observations`
    WHERE NOT isnull(park_id)
    GROUP BY ride_id, ride_name, park_id, park_name
    ORDER BY park_id asc, ride_id asc
)

SELECT *
FROM rides
  