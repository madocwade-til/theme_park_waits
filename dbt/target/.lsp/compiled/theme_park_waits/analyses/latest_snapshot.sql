select max(observed_at_utc) as latest_snapshot
FROM `deng_accelerator`.`raw_data`.`_stg_snapshots`