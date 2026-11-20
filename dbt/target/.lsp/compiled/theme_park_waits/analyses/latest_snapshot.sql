select max(observed_at_utc) as latest_snapshot
FROM `deng_accelerator`.`output`.`_stg_snapshots`