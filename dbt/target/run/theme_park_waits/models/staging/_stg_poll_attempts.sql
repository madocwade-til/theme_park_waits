
  
  
  
  create or replace view `deng_accelerator`.`output`.`_stg_poll_attempts`
  
  as (
    SELECT *
FROM `deng_accelerator`.`raw_data`.`poll_attempts`
  )
