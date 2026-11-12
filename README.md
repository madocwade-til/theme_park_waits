# Theme park wait-time history starter

[Powered by Queue-Times.com](https://queue-times.com/)

Collect live ride waits every five minutes and append them to a local SQLite database. Python 3.10+; no external Python packages, API key or database server required. Windows, macOS and Linux are supported. This is a standalone starter you can place in your Accelerator_Project folder.

## Start on Windows / VS Code

Extract this folder and open a terminal inside it. Use your existing virtual environment or create one:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python main.py list-parks
```

Edit `config.json` and choose `park_ids` from that list. The shipped `[2]` is Thorpe Park, the API documentation's example, not an inferred preference. Multiple parks: `"park_ids": [2, 6]` (confirm ids with `list-parks`). Parks may be closed seasonally; choose parks currently operating if you want immediate changing waits.

```powershell
python main.py once
python main.py run
```

`once` collects one snapshot for each selected park. `run` immediately collects, then repeats every 300 seconds until Ctrl+C. History begins when you run it. Collection stops while the process or computer is off. There is no backfill for missed intervals through these documented live endpoints.

The first successful run creates `data/wait_times.sqlite3`. Paths in config are relative to the config file, so scheduled runs use the same database regardless of working directory. `interval_seconds` must be a multiple of 300. Logs rotate in `logs/ingestion.log`; timestamps in logs and database are UTC.

## Keep collecting regularly

For a trial, leave `python main.py run` running. For Windows Task Scheduler, first confirm `once` works, then run:

```powershell
.\register_windows_task.ps1 -PythonPath "$PWD\.venv\Scripts\python.exe"
```

This explicitly registers `ThemeParkWaitsCollector`, runs `once` every five minutes, and skips overlapping task instances. It uses the current user's default interactive task context; treat it as a logged-in workstation setup. Configure Windows Task Scheduler separately if you need collection while logged out. The computer must be awake and connected. Check Task Scheduler's history and `logs/ingestion.log` after registration. The script has not been executed or tested on Windows here. Its five-minute repetition is independent of `interval_seconds`; change the script as well if you choose another interval. Do not also run continuous mode against the same database.

Remove the task with:

```powershell
Unregister-ScheduledTask -TaskName ThemeParkWaitsCollector
```

For Linux/macOS cron, use absolute paths (quote any paths containing spaces):

```cron
*/5 * * * * /absolute/path/to/python /absolute/path/to/theme_park_waits/main.py once --config /absolute/path/to/theme_park_waits/config.json
```

For continuous unattended collection, deploy the project and its persistent database on an always-on machine. No external collector has been deployed as part of this starter.

## What gets stored

| Object | Grain / purpose |
|---|---|
| `parks` | Current park metadata including coordinates and IANA timezone |
| `snapshots` | One successful park response per five-minute UTC slot, raw JSON and collection time |
| `wait_observations` | One ride per snapshot: name, land, open status, reported wait, source update time |
| `poll_attempts` | Successful, skipped and failed park requests |
| `catalog_cache` | Park directory cached for 24 hours; last catalog used if refresh fails |
| `wait_times` | Joined analytical view, including cleaned wait and source age |

Snapshots and observations are appended; existing successful snapshots are never overwritten. Re-running in the same five-minute slot skips an existing park snapshot. The first success wins, including overlapping invocations. Unchanged readings in later slots are retained deliberately: this represents repeated sampling over time. Do not call these independent source updates in an analysis. Failed parks are logged and other parks continue. Malformed park snapshots fail as a unit instead of writing a partial ride list. HTTP retries cover transient network errors, 429 and selected 5xx responses; nonretryable errors surface in logs. A completely failed catalog lookup before park selection is recorded in the log, rather than fabricated park readings. `once` returns exit code 1 if any selected park fails.

Both nested `lands[].rides[]` and top-level `rides[]` are ingested. Exact duplicate rides are collapsed, preserving a land assignment; conflicting duplicates fail validation. Raw reported values and source responses are kept for later debugging.

## Analysis and export

```powershell
python main.py export
python main.py export --output data/my_waits.csv
```

Export is UTF-8 CSV, one ride per collected snapshot, suitable for Python/R/Tableau. SQLite can also be read directly:

```python
import sqlite3
import pandas as pd  # optional; install separately if not already available

with sqlite3.connect("data/wait_times.sqlite3") as connection:
    df = pd.read_sql_query("SELECT * FROM wait_times", connection)

# Derive local dates/hours separately for each park; handles daylight saving.
# Windows may require: pip install tzdata
for park_id, park in df.groupby("park_id"):
    local_time = pd.to_datetime(park["observed_at_utc"], utc=True).dt.tz_convert(
        park["park_timezone"].iloc[0]
    )
    print(park_id, local_time.dt.hour.value_counts().sort_index())
```

`sql/analysis.sql` contains daily ride averages, failure counts and stale-source checks. Those daily summaries use UTC dates explicitly; use park-local dates for comparisons of operating days and time of day.

Analytical choices to preserve:

- These are **posted waits**, not measured time spent queuing or attendance counts.
- `reported_wait_minutes` retains source zeroes, nulls and negative sentinels. In `wait_minutes`, closed rides and negative values become NULL. An open zero remains a real zero.
- Keep `observed_at_utc` separate from `source_updated_at_utc`. An old source timestamp remains an old reading even if we just fetched it. The example SQL excludes missing/future/stale timestamps using a documented 15-minute tolerance; adjust after inspecting source behavior.
- A closed ride does not prove a breakdown: the park may be outside operating hours or closed for the season. Missing rides and failed requests do not become zero waits. Operating schedules would be a separate future input.
- Averages are sampled means. Gaps, uneven park/ride coverage and changing attraction lists can bias comparisons. Inspect sample counts and use comparable time windows and ride sets before comparing parks or years.
- At five-minute intervals, 50 rides yield up to 14,400 ride rows daily. Raw JSON also consumes disk. Monitor growth and back up the database; never replace it with a fresh copy during redeployment. Stop collection before making a simple file copy, or use SQLite's backup API while running.

## Files and validation

`api.py` handles requests, `database.py` validates and stores data, `main.py` handles configuration and commands. `tests/test_ingestion.py` uses explicitly synthetic fixtures to verify data correctness, deduplication, partial failure handling, retries and export.

```powershell
python -m unittest discover -s tests -v
```

Local validation and source access limitations are recorded in `docs/validation.md`. Research on optional historical sources is in `docs/historical_sources.md`; no historical data or additional services are imported automatically.

API documentation: https://queue-times.com/pages/api . The provider documents a five-minute update cadence and requires the attribution link shown above. Keep it prominent in any dashboard or app you later build.
