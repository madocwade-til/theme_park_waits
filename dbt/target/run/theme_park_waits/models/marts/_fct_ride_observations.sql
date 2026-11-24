
  
    



create or replace transient  table DENG_ACCELERATOR.TABLES._fct_ride_observations
    
    
    
    
    as (SELECT *
FROM DENG_ACCELERATOR.TABLES._int_ride_parks
    )
;



  