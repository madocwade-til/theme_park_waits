
  
    



create or replace transient  table DENG_ACCELERATOR.TABLES._fct_daily_park_performance
    
    
    
    
    as (with parks as (
    SELECT *
    FROM DENG_ACCELERATOR.TABLES._stg_parks
),



SELECT * FROM daily_summary
    )
;



  