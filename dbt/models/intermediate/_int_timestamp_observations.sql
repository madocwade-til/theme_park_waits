with joined as (
    SELECT o.*, s.observed_at_utc, CAST(observed_at_utc AS DATE) as observation_day
    FROM {{ref('_stg_wait_observations')}} o
    LEFT JOIN {{ref('_stg_snapshots')}} s
)

SELECT *
FROM joined