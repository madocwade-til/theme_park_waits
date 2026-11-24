SELECT *
FROM DENG_ACCELERATOR.TABLES._fct_daily_ride_performance
WHERE relative_diff > 100
ORDER BY relative_diff desc