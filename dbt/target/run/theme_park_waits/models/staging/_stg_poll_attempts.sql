
  create or replace   view DENG_ACCELERATOR.TABLES._stg_poll_attempts
  
  
  
  
  as (
    SELECT *
FROM deng_accelerator.raw_data.poll_attempts
  );

