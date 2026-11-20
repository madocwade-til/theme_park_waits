
  
  
  
  create or replace view `deng_accelerator`.`output`.`_stg_snapshots`
  
  as (
    SELECT *
FROM `deng_accelerator`.`raw_data`.`snapshots`
  )
