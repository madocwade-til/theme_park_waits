
  
    
        create or replace table `deng_accelerator`.`output`.`_fct_daily_park_performance`
      
      
    
      using delta
    
  
      
      
      
      
      
      
      
      
      as
      with parks as (
    SELECT
    FROM `deng_accelerator`.`output`.`_stg_parks`
),

daily_summary as (
    SELECT
    FROM 
)

SELECT * FROM daily_summary
  