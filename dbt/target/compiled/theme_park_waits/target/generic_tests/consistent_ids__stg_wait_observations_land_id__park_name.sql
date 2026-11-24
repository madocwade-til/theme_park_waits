

SELECT m1.*, 
m2.land_id as id_col2, 
m2.park_name as name_col2
FROM DENG_ACCELERATOR.TABLES._stg_wait_observations m1
LEFT JOIN DENG_ACCELERATOR.TABLES._stg_wait_observations m2
ON m1.land_id == m2.land_id
HAVING m1.park_name != m2.park_name

