
  
    
        create or replace table `deng_accelerator`.`output`.`_dim_parks`
      
      
    
      using delta
    
  
      
      
      
      
      
      
      
      
      as
      SELECT *
FROM `deng_accelerator`.`output`.`_stg_parks`
  