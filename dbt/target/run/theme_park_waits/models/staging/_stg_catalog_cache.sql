
  create or replace   view DENG_ACCELERATOR.TABLES._stg_catalog_cache
  
  
  
  
  as (
    SELECT *
FROM deng_accelerator.raw_data.catalog_cache
  );

