
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  

SELECT m1.*, 
m2.park_id as id_col2, 
m2.park_name as name_col2
FROM DENG_ACCELERATOR.TABLES._stg_wait_observations m1
LEFT JOIN DENG_ACCELERATOR.TABLES._stg_wait_observations m2
ON m1.park_id = m2.park_id
WHERE m1.park_name != m2.park_name


  
  
      
    ) dbt_internal_test