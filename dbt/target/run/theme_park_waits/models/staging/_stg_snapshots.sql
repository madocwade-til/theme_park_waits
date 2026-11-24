
  create or replace   view DENG_ACCELERATOR.TABLES._stg_snapshots
  
  
  
  
  as (
    SELECT *
FROM deng_accelerator.raw_data.snapshots
  );

