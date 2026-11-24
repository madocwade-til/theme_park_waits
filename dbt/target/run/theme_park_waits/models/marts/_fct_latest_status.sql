
  
    



create or replace transient  table DENG_ACCELERATOR.TABLES._fct_latest_status
    
    
    
    
    as (with ranked_data as (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY ride_id
        ORDER BY snapshot_id desc
    ) AS rn
    FROM DENG_ACCELERATOR.TABLES._int_ride_parks
),

latest_status as (
    SELECT *
    FROM ranked_data
    WHERE rn = 1
)

SELECT ride_id, land_id, park_id, is_open
FROM latest_status
    )
;



  