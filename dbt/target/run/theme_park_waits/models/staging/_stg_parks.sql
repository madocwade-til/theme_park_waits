
  
  
  
  create or replace view `deng_accelerator`.`output`.`_stg_parks`
  
  as (
    SELECT *
FROM `deng_accelerator`.`raw_data`.`parks`
  )
