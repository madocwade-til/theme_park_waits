select max(observed_at_utc) as latest_snapshot
FROM {{ref('_stg_snapshots')}}