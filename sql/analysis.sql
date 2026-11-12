-- SQLite: daily means by ride, based on collection day in UTC.
-- Closed rides/negative waits become NULL in wait_times; open zeroes are retained.
-- 15-minute freshness tolerance is an analytical choice, not an API guarantee.
SELECT park_id, park_name, ride_id, ride_name,
       date(observed_at_utc) AS day_utc,
       COUNT(*) AS collected_samples,
       COUNT(CASE WHEN source_age_seconds BETWEEN -60 AND 900
                       THEN wait_minutes END) AS valid_open_samples,
       ROUND(AVG(CASE WHEN source_age_seconds BETWEEN -60 AND 900
                       THEN wait_minutes END), 1) AS avg_wait_minutes,
       MAX(CASE WHEN source_age_seconds BETWEEN -60 AND 900
                       THEN wait_minutes END) AS max_wait_minutes
FROM wait_times
GROUP BY park_id, park_name, ride_id, ride_name, date(observed_at_utc);

-- Monitor ingestion failures separately from a reported closed ride.
SELECT park_id, status, COUNT(*) AS attempts
FROM poll_attempts GROUP BY park_id, status;

-- Recent source lag / missing source timestamps.
SELECT park_id, ride_name, observed_at_utc, source_updated_at_utc, source_age_seconds
FROM wait_times
WHERE source_age_seconds IS NULL OR source_age_seconds > 900
ORDER BY observed_at_utc DESC LIMIT 100;
