"""Offline tests: all park/ride fixtures below are synthetic."""
import copy
from datetime import datetime, timezone
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError

import api
from database import connect, normalize_rides, save_snapshot
from main import collect_once, export_csv

PARK = {"id": 2, "name": "Test Park", "country": "Test Country",
        "timezone": "Europe/London"}
NOW = datetime(2026, 11, 10, 12, 0, tzinfo=timezone.utc)
PAYLOAD = {"lands": [{"id": 1, "name": "Test Land", "rides": [
    {"id": 10, "name": "Closed Ride", "is_open": False, "wait_time": 0,
     "last_updated": "2026-11-10T12:00:00Z"}]}], "rides": [
    {"id": 11, "name": "Walk On", "is_open": True, "wait_time": 0,
     "last_updated": "2026-11-10T11:59:00Z"}]}


class DatabaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.db = connect(Path(self.temp.name) / "test.sqlite3")

    def tearDown(self):
        self.db.close()
        self.temp.cleanup()

    def test_closed_zero_and_open_zero_are_distinct(self):
        save_snapshot(self.db, PARK, PAYLOAD, NOW, 1)
        rows = self.db.execute("SELECT * FROM wait_times ORDER BY ride_id").fetchall()
        self.assertIsNone(rows[0]["wait_minutes"])
        self.assertEqual(rows[0]["reported_wait_minutes"], 0)
        self.assertEqual(rows[1]["wait_minutes"], 0)
        self.assertEqual(rows[1]["source_age_seconds"], 60)

    def test_slot_retry_is_idempotent_but_later_unchanged_poll_is_kept(self):
        self.assertEqual(save_snapshot(self.db, PARK, PAYLOAD, NOW, 1), 2)
        self.assertIsNone(save_snapshot(self.db, PARK, PAYLOAD, NOW, 1))
        self.assertEqual(save_snapshot(self.db, PARK, PAYLOAD, NOW, 2), 2)
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM snapshots").fetchone()[0], 2)
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM wait_observations").fetchone()[0], 4)

    def test_invalid_snapshot_does_not_partially_append(self):
        broken = copy.deepcopy(PAYLOAD)
        broken["rides"][0]["is_open"] = "false"
        with self.assertRaises(ValueError):
            save_snapshot(self.db, PARK, broken, NOW, 1)
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM snapshots").fetchone()[0], 0)
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM parks").fetchone()[0], 0)

    def test_transaction_rolls_back_on_database_failure(self):
        self.db.execute("""CREATE TRIGGER test_fail_second_ride
            BEFORE INSERT ON wait_observations WHEN NEW.ride_id=11
            BEGIN SELECT RAISE(ABORT, 'Injected database failure'); END""")
        with self.assertRaises(Exception):
            save_snapshot(self.db, PARK, PAYLOAD, NOW, 1)
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM snapshots").fetchone()[0], 0)
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM wait_observations").fetchone()[0], 0)
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM parks").fetchone()[0], 0)

    def test_flat_and_nested_rides_duplicate_handling(self):
        data = copy.deepcopy(PAYLOAD)
        data["rides"].append(copy.deepcopy(data["lands"][0]["rides"][0]))
        self.assertEqual(len(normalize_rides(data)), 2)
        data["rides"][-1]["wait_time"] = 99
        with self.assertRaises(ValueError):
            normalize_rides(data)

    def test_null_negative_and_absent_updates_are_preserved(self):
        data = copy.deepcopy(PAYLOAD)
        data["rides"][0].update(wait_time=-999, last_updated=None)
        save_snapshot(self.db, PARK, data, NOW, 1)
        row = self.db.execute("SELECT * FROM wait_times WHERE ride_id=11").fetchone()
        self.assertEqual(row["reported_wait_minutes"], -999)
        self.assertIsNone(row["wait_minutes"])
        self.assertIsNone(row["source_age_seconds"])

    @patch("main.api.get_wait_times")
    @patch("main.load_catalog")
    def test_one_failed_park_does_not_block_another(self, catalog, waits):
        catalog.return_value = [PARK, {**PARK, "id": 3}]
        waits.side_effect = [RuntimeError("Test upstream failure"), PAYLOAD]
        with self.assertLogs(level="ERROR"):
            self.assertEqual(collect_once(self.db, {"park_ids": [2, 3]}), 1)
        self.assertEqual(self.db.execute("SELECT park_id FROM snapshots").fetchone()[0], 3)
        statuses = [r[0] for r in self.db.execute("SELECT status FROM poll_attempts ORDER BY attempt_id")]
        self.assertEqual(statuses, ["failed", "success"])

    def test_csv_export_and_analysis_queries(self):
        save_snapshot(self.db, PARK, PAYLOAD, NOW, 1)
        target = Path(self.temp.name) / "out.csv"
        export_csv(self.db, target)
        import csv
        with target.open(newline="") as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["park_timezone"], "Europe/London")
        sql = (Path(__file__).parents[1] / "sql" / "analysis.sql").read_text()
        self.db.executescript(sql)


class ApiTests(unittest.TestCase):
    @patch("api.time.sleep")
    @patch("api.urlopen")
    def test_transient_http_errors_retry(self, open_url, sleep):
        error = HTTPError("https://example.test", 429, "Rate limit", {"Retry-After": "3"}, None)
        open_url.side_effect = [error, error, error]
        with self.assertRaises(RuntimeError):
            api.get_json("/test")
        self.assertEqual(open_url.call_count, 3)
        self.assertEqual(sleep.call_count, 2)
        sleep.assert_called_with(3.0)

    @patch("api.time.sleep")
    @patch("api.urlopen")
    def test_404_is_not_retried(self, open_url, sleep):
        open_url.side_effect = HTTPError("https://example.test", 404, "Missing", {}, None)
        with self.assertRaises(HTTPError):
            api.get_json("/test")
        sleep.assert_not_called()


if __name__ == "__main__":
    unittest.main()
