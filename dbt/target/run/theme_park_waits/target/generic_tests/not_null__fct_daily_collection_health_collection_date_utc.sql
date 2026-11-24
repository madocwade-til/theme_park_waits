
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select collection_date_utc
from DENG_ACCELERATOR.TABLES._fct_daily_collection_health
where collection_date_utc is null



  
  
      
    ) dbt_internal_test