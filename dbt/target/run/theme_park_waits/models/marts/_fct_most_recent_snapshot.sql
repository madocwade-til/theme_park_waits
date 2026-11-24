
  
    



create or replace transient  table DENG_ACCELERATOR.TABLES._fct_most_recent_snapshot
    
    
    
    
    as (
select max(observed_at_utc) as latest_snapshot
FROM DENG_ACCELERATOR.TABLES._stg_snapshots
    )
;



  