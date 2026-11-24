
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select park_id
from DENG_ACCELERATOR.TABLES._fct_daily_collection_health
where park_id is null



  
  
      
    ) dbt_internal_test