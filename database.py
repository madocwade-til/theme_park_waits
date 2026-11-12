"""Append snapshots atomically; park metadata and catalog cache are refreshed."""
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path


def utc_now():
    return datetime.now(timezone.utc)


def timestamp(value):
    if value.tzinfo is None:
        raise ValueError("Timestamp must include a timezone")
    return value.astimezone(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def source_timestamp(value):
    if value is None:
        return None
    return timestamp(datetime.fromisoformat(value.replace("Z", "+00:00")))


def connect(path):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(path, timeout=30)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA foreign_keys = ON")
    db.execute("PRAGMA journal_mode = WAL")
    db.executescript((Path(__file__).parent / "sql" / "schema.sql").read_text())
    return db


def normalize_rides(payload):
    if not isinstance(payload, dict) or not ({"lands", "rides"} & payload.keys()):
        raise ValueError("Expected a queue payload with lands and/or rides")
    rows = {}
    containers = [(land.get("id"), land.get("name"), land["rides"])
                  for land in payload.get("lands", [])]
    containers.append((None, None, payload.get("rides", [])))
    for land_id, land_name, rides in containers:
        for ride in rides:
            ride_id = ride["id"]
            if type(ride_id) is not int or ride_id <= 0:
                raise ValueError("Ride id must be a positive integer")
            if type(ride["is_open"]) is not bool:
                raise ValueError(f"Ride {ride_id}: is_open must be boolean")
            wait = ride.get("wait_time")
            if wait is not None and type(wait) is not int:
                raise ValueError(f"Ride {ride_id}: wait_time must be integer or null")
            row = (ride_id, ride["name"], land_id, land_name,
                   int(ride["is_open"]), wait, source_timestamp(ride.get("last_updated")))
            # Prefer the land assignment if the same ride appears at the root too.
            if ride_id in rows:
                previous = rows[ride_id]
                if previous[:2] != row[:2] or previous[4:] != row[4:]:
                    raise ValueError(f"Conflicting duplicate ride {ride_id}")
            else:
                rows[ride_id] = row
    return list(rows.values())


def save_snapshot(db, park, payload, observed_at, poll_slot):
    """Return inserted ride count, or None for an existing park/5-minute slot."""
    rows = normalize_rides(payload)
    with db:
        db.execute("""INSERT INTO parks VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(park_id) DO UPDATE SET
            name=excluded.name, country=excluded.country, latitude=excluded.latitude,
            longitude=excluded.longitude, timezone=excluded.timezone,
            group_name=excluded.group_name, refreshed_at_utc=excluded.refreshed_at_utc""",
            (park["id"], park["name"], park.get("country"), park.get("latitude"),
             park.get("longitude"), park["timezone"], park.get("group_name"),
             timestamp(observed_at)))
        result = db.execute("""INSERT INTO snapshots
            (park_id, poll_slot, observed_at_utc, source_url, raw_json)
            VALUES (?, ?, ?, ?, ?) ON CONFLICT(park_id, poll_slot) DO NOTHING""",
            (park["id"], poll_slot, timestamp(observed_at),
             f'https://queue-times.com/parks/{park["id"]}/queue_times.json',
             json.dumps(payload, ensure_ascii=False)))
        if result.rowcount == 0:
            return None
        db.executemany("INSERT INTO wait_observations VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                       [(result.lastrowid, *row) for row in rows])
    return len(rows)


def record_attempt(db, park_id, slot, status, detail):
    with db:
        db.execute("""INSERT INTO poll_attempts
            (park_id, poll_slot, finished_at_utc, status, detail) VALUES (?, ?, ?, ?, ?)""",
            (park_id, slot, timestamp(utc_now()), status, detail))
