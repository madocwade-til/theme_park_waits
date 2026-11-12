"""Run: python main.py list-parks | once | run | export."""
import argparse
import csv
import json
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path
import sys
import time

import api
from database import connect, record_attempt, save_snapshot, timestamp, utc_now

ROOT = Path(__file__).resolve().parent


def load_config(path):
    config = json.loads(path.read_text(encoding="utf-8"))
    ids = config["park_ids"]
    if not ids or any(type(x) is not int or x <= 0 for x in ids):
        raise ValueError("park_ids must contain positive integer park ids")
    if len(ids) != len(set(ids)):
        raise ValueError("park_ids contains duplicates")
    interval = config["interval_seconds"]
    if type(interval) is not int or interval < 300 or interval % 300:
        raise ValueError("interval_seconds must be a multiple of 300, at least 300")
    for field in ("database_path", "log_path"):
        config[field] = (path.parent / config[field]).resolve()
    return config


def setup_logging(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        handlers=[logging.StreamHandler(), RotatingFileHandler(
            path, maxBytes=2_000_000, backupCount=3, encoding="utf-8")])
    logging.Formatter.converter = time.gmtime


def load_catalog(db):
    cached = db.execute("SELECT * FROM catalog_cache WHERE singleton=1").fetchone()
    if cached:
        from datetime import datetime
        age = (utc_now() - datetime.fromisoformat(
            cached["fetched_at_utc"].replace("Z", "+00:00"))).total_seconds()
        if age < 86400:
            return json.loads(cached["raw_json"])
    try:
        parks = api.get_parks()
        if not parks:
            raise ValueError("Empty park catalog")
        with db:
            db.execute("INSERT OR REPLACE INTO catalog_cache VALUES (1, ?, ?)",
                       (timestamp(utc_now()), json.dumps(parks)))
        return parks
    except Exception:
        if not cached:
            raise
        logging.warning("Catalog refresh failed; using cached metadata", exc_info=True)
        return json.loads(cached["raw_json"])


def collect_once(db, config):
    catalog = {p["id"]: p for p in load_catalog(db)}
    unknown = set(config["park_ids"]) - catalog.keys()
    if unknown:
        raise ValueError(f"Unknown park ids {sorted(unknown)}; run list-parks")
    # Fixed 5-minute UTC slots make scheduler retries and overlapping invocations safe.
    slot = int(time.time()) // 300
    failures = 0
    for park_id in config["park_ids"]:
        if db.execute("SELECT 1 FROM snapshots WHERE park_id=? AND poll_slot=?",
                      (park_id, slot)).fetchone():
            record_attempt(db, park_id, slot, "skipped", "Snapshot already collected")
            continue
        try:
            payload = api.get_wait_times(park_id)
            count = save_snapshot(db, catalog[park_id], payload, utc_now(), slot)
        except Exception as error:
            failures += 1
            logging.exception("Park %s failed; continuing to the next park", park_id)
            record_attempt(db, park_id, slot, "failed", str(error))
        else:
            status = "skipped" if count is None else "success"
            record_attempt(db, park_id, slot, status, f"{count or 0} ride rows")
            logging.info("Park %s: %s (%s rides)", park_id, status, count or 0)
    return failures


def export_csv(db, output):
    output.parent.mkdir(parents=True, exist_ok=True)
    cursor = db.execute("SELECT * FROM wait_times ORDER BY observed_at_utc, park_id, ride_id")
    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow([column[0] for column in cursor.description])
        writer.writerows(cursor)
    logging.info("Exported %s", output)


def main():
    parser = argparse.ArgumentParser(description="Powered by Queue-Times.com — https://queue-times.com/")
    parser.add_argument("command", choices=["list-parks", "once", "run", "export"])
    parser.add_argument("--config", type=Path, default=ROOT / "config.json")
    parser.add_argument("--output", type=Path, default=ROOT / "data" / "wait_times.csv")
    args = parser.parse_args()
    if args.command == "list-parks":
        print("Powered by Queue-Times.com — https://queue-times.com/")
        for park in api.get_parks():
            print(f'{park["id"]:>5}  {park["name"]} | {park["country"]} | {park["timezone"]}')
        return 0
    config = load_config(args.config.resolve())
    setup_logging(config["log_path"])
    logging.info("Powered by Queue-Times.com — https://queue-times.com/")
    db = connect(config["database_path"])
    try:
        if args.command == "export":
            export_csv(db, args.output.resolve())
            return 0
        if args.command == "once":
            return 1 if collect_once(db, config) else 0
        while True:
            started = time.monotonic()
            try:
                collect_once(db, config)
            except Exception:
                logging.exception("Collection cycle failed; will retry next cycle")
            # Skip missed cycles rather than issuing catch-up requests in a burst.
            elapsed = time.monotonic() - started
            interval = config["interval_seconds"]
            time.sleep(interval - elapsed % interval)
    finally:
        db.close()


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("Stopped collection.")
    except Exception:
        logging.exception("Command failed")
        sys.exit(1)
