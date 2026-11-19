
  
  
  
  create or replace view `deng_accelerator`.`raw_data`.`_stg_snapshots`
  
  as (
    SELECT *
FROM `deng_accelerator`.`raw_data`.`snapshots`
  )
