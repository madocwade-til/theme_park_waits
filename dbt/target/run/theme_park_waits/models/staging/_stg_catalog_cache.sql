
  
  
  
  create or replace view `deng_accelerator`.`output`.`_stg_catalog_cache`
  
  as (
    SELECT *
FROM `deng_accelerator`.`raw_data`.`catalog_cache`
  )
