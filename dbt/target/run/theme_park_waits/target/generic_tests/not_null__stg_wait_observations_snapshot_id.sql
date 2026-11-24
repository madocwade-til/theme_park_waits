
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select snapshot_id
from DENG_ACCELERATOR.TABLES._stg_wait_observations
where snapshot_id is null



  
  
      
    ) dbt_internal_test