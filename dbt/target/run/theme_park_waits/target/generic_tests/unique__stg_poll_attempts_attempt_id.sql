
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    attempt_id as unique_field,
    count(*) as n_records

from DENG_ACCELERATOR.TABLES._stg_poll_attempts
where attempt_id is not null
group by attempt_id
having count(*) > 1



  
  
      
    ) dbt_internal_test