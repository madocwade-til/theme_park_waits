with joined as (
    SELECT o.*, s.observed_at_utc, CAST(observed_at_utc AS DATE) as observation_day
    FROM `deng_accelerator`.`output`.`_stg_wait_observations` o
    LEFT JOIN `deng_accelerator`.`output`.`_stg_snapshots` s
)

SELECT *
FROM joined