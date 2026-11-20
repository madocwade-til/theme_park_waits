
  
  
  
  create or replace view `deng_accelerator`.`output`.`_int_most_recent_snapshot`
  
  as (
    select max(observed_at_utc) as latest_snapshot
FROM `deng_accelerator`.`output`.`_stg_snapshots`
  )
