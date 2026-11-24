
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select attempt_id
from DENG_ACCELERATOR.TABLES._stg_poll_attempts
where attempt_id is null



  
  
      
    ) dbt_internal_test