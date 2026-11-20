with parks as (
    SELECT *
    FROM {{ref('_stg_parks')}}
),



SELECT * FROM daily_summary