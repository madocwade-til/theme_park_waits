
  create or replace   view DENG_ACCELERATOR.TABLES._int_most_recent_snapshot
  
  
  
  
  as (
    
select max(observed_at_utc) as latest_snapshot
FROM DENG_ACCELERATOR.TABLES._stg_snapshots
  );

