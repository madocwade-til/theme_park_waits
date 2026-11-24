
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select poll_slot
from DENG_ACCELERATOR.TABLES._stg_poll_attempts
where poll_slot is null



  
  
      
    ) dbt_internal_test