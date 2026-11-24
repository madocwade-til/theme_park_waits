
  
    



create or replace transient  table DENG_ACCELERATOR.TABLES._fct_!daily_park_performance
    
    
    
    
    as (with obs as (
    SELECT *
    FROM DENG_ACCELERATOR.TABLES._int_ride_parks
),





SELECT park_id, land_id, ride_id, AVG() FROM 
    )
;



  