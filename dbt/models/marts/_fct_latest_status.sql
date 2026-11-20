with ranked_data as (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY ride_id
        ORDER BY snapshot_id desc
    ) AS rn
    FROM {{ref('_stg_wait_observations')}}
),

latest_status as (
    SELECT *
    FROM ranked_data
    WHERE rn = 1
)

SELECT *
FROM latest_status