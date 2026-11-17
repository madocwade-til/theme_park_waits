CREATE TABLE IF NOT EXISTS parks (
    park_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    country TEXT,
    latitude REAL,
    longitude REAL,
    timezone TEXT NOT NULL,
    group_name TEXT,
    refreshed_at_utc TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS catalog_cache (
    singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
    fetched_at_utc TEXT NOT NULL,
    raw_json TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS snapshots (
    snapshot_id INTEGER PRIMARY KEY,
    park_id INTEGER NOT NULL REFERENCES parks(park_id),
    poll_slot INTEGER NOT NULL,
    observed_at_utc TEXT NOT NULL,
    source_url TEXT NOT NULL,
    raw_json TEXT NOT NULL,
    UNIQUE (park_id, poll_slot)
);

CREATE TABLE IF NOT EXISTS wait_observations (
    snapshot_id INTEGER NOT NULL REFERENCES snapshots(snapshot_id),
    ride_id INTEGER NOT NULL,
    ride_name TEXT NOT NULL,
    land_id INTEGER,
    land_name TEXT,
    is_open INTEGER NOT NULL CHECK (is_open IN (0, 1)),
    reported_wait_minutes INTEGER,
    source_updated_at_utc TEXT,
    PRIMARY KEY (snapshot_id, ride_id)
);

CREATE TABLE IF NOT EXISTS poll_attempts (
    attempt_id INTEGER PRIMARY KEY,
    park_id INTEGER NOT NULL,
    poll_slot INTEGER NOT NULL,
    finished_at_utc TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('success', 'failed', 'skipped')),
    detail TEXT
);

CREATE INDEX IF NOT EXISTS idx_snapshot_park_time ON snapshots(park_id, observed_at_utc);
CREATE INDEX IF NOT EXISTS idx_observation_ride ON wait_observations(ride_id, snapshot_id);

CREATE VIEW IF NOT EXISTS wait_times AS
SELECT s.snapshot_id, s.park_id, p.name AS park_name, p.country,
       p.timezone AS park_timezone, s.poll_slot, s.observed_at_utc,
       w.ride_id, w.ride_name, w.land_id, w.land_name, w.is_open,
       w.reported_wait_minutes,
       CASE WHEN w.is_open = 1 AND w.reported_wait_minutes >= 0
            THEN w.reported_wait_minutes END AS wait_minutes,
       w.source_updated_at_utc,
       ROUND((julianday(s.observed_at_utc) - julianday(w.source_updated_at_utc))
             * 86400) AS source_age_seconds
FROM wait_observations w
JOIN snapshots s USING (snapshot_id)
JOIN parks p USING (park_id);
