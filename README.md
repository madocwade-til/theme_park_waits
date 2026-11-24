# Theme park wait-time history

[Powered by Queue-Times.com](https://queue-times.com/)

This project collects posted ride wait times from Queue-Times, stores the observations in SQLite, and loads a daily copy into Snowflake. dbt cleans the raw tables and builds models for ride waits, daily park performance, and collection health.

| Step | What runs | When |
| --- | --- | --- |
| Collect | `python/main.py run` polls Queue-Times and writes to SQLite. | Every five minutes while the collector is running. |
| Upload | `python/upload_sqlite.py` takes a SQLite backup and loads its tables into Snowflake. | Once per day through a scheduled job. |
| Transform | `dbt build` builds the models and runs the configured data tests. | After the Snowflake upload succeeds. |

## Set up a fresh clone

You’ll need Git, Python 3.10 or newer, a Snowflake-capable dbt CLI, and a Snowflake role that can use your warehouse, load tables into the raw schema, and build models in the dbt output schema. Install the dbt CLI on the machine that will run the pipeline and confirm `dbt --version` works.

Clone the repo using its Git URL and run the setup commands from the clone root. Replace the example URL with the one from your Git host.

```sh
git clone https://example.com/your-org/theme_park_waits.git
cd theme_park_waits
```

**Windows PowerShell**

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install "snowflake-connector-python[pandas]" python-dotenv
```

**Linux or macOS**

```sh
python3 -m venv .venv
.venv/bin/python -m pip install 'snowflake-connector-python[pandas]' python-dotenv
```

### Configure Snowflake and dbt

1. Create a `.env` file in the clone root. Use your existing Snowflake database and choose a raw schema dedicated to the load. The `SNOWFLAKE_SCHEMA` value is the raw destination. The uploader replaces the contents of its target tables on each successful run.

   ```dotenv
   SNOWFLAKE_ACCOUNT=
   SNOWFLAKE_USER=
   SNOWFLAKE_PASSWORD=
   SNOWFLAKE_WAREHOUSE=
   SNOWFLAKE_DATABASE=
   SNOWFLAKE_SCHEMA=
   SNOWFLAKE_ROLE=
   ```

   Fill in the values for your Snowflake account and keep `.env` out of Git.

2. Create a Snowflake profile in `~/.dbt/profiles.yml` under the account that will run dbt. Match the profile name to the `profile:` setting in `dbt/dbt_project.yml`. Set its database to your chosen database and its schema to the output schema you want dbt to build in, for example `ANALYTICS`. Use a dedicated output schema so dbt models and raw tables are easy to distinguish. For unattended runs, use credentials that work without an interactive sign-in. [Configure a Snowflake profile](https://docs.getdbt.com/docs/local/connect-data-platform/snowflake-setup?version=2)

3. In the dbt source YAML under `dbt/models/`, set the Snowflake source database and schema to the same values as `SNOWFLAKE_DATABASE` and `SNOWFLAKE_SCHEMA`. If the profile or sources use environment variables, supply them to the shell or scheduler account that runs dbt. The uploader’s `.env` is read inside Python, so dbt needs its own access to the settings.

## Collect ride observations

```powershell
.\.venv\Scripts\python.exe .\python\main.py list-parks
.\.venv\Scripts\python.exe .\python\main.py once
.\.venv\Scripts\python.exe .\python\main.py run
```

On Linux or macOS, use `.venv/bin/python python/main.py` with the same subcommands.

Use `list-parks` to find IDs and set `park_ids` in the collector's `config.json`. Use `once` to verify the configuration. Use `run` in a dedicated terminal window for continuous collection, and press **Ctrl+C** to stop. The collector needs an awake machine and an internet connection. Missed polls leave gaps in the record because the live endpoints serve current readings. The collector and uploader should point to the same `wait_times.sqlite3` database. On a server, keep it on persistent storage writable by the collector and readable by the upload job.

The collector retries transient API errors and records failures by park. Other parks continue when one park fails. A repeat collection in the same five-minute slot skips a park if a snapshot already exists. The same reported wait can appear in later slots because each poll is a separate sample.

| SQLite table | Grain or purpose |
| --- | --- |
| `parks` | One row per park with its current metadata, including its IANA time zone. |
| `snapshots` | One successful API response per park and five-minute UTC slot. Stores the poll time and raw JSON. |
| `wait_observations` | One ride per snapshot. Stores open status, posted wait, and source update time. |
| `poll_attempts` | One record per logged attempt, with status `success`, `failed`, or `skipped`. |
| `catalog_cache` | The most recently cached park directory. |

## Run the daily load and dbt build

After the first successful poll, run the upload from the clone root. Once it succeeds, run `dbt debug` and `dbt build` from the `dbt/` directory. On Windows, use:

```powershell
.\.venv\Scripts\python.exe .\python\upload_sqlite.py
Push-Location .\dbt
try {
    dbt debug
    dbt build
} finally {
    Pop-Location
}
```

The upload takes a consistent SQLite backup so the collector can keep writing while Snowflake is loading. It creates missing raw tables and reloads the full contents of existing ones. Two successful runs against the same snapshot leave the same set of rows. Each table loads separately, so a failure partway through can leave tables from different runs until the next successful upload.

### Windows Task Scheduler

Use the root-level `run_daily.ps1` to run both steps together. Set its dbt executable path for the machine running the task. If dbt was installed with WinGet, find the executable with `(Get-Command dbt).Source`. The script runs dbt from the `dbt/` directory and checks the upload exit code before starting the build.

```powershell
.\run_daily.ps1
```

In Windows Task Scheduler, create a daily trigger at a time the machine is usually awake. Use these action settings:

| Field | Value |
| --- | --- |
| Program/script | `powershell.exe` |
| Add arguments | `-NoProfile -File "C:\path\to\theme_park_waits\run_daily.ps1"` |
| Start in | Leave blank when the script resolves paths from `$PSScriptRoot`. |

Use the Windows account that can read the dbt profile and authenticate to Snowflake. Enable **Run task as soon as possible after a scheduled start is missed** and choose **Do not start a new instance** if the task is already running. Run the task manually from Task Scheduler and check its last run result and the updated Snowflake tables. The collector remains a separate process that you start and stop.

### Linux or macOS server

Run the collector separately. Use `.venv/bin/python python/main.py run` from the clone root if you want to start and stop it manually. For unattended collection, run that command under a service manager with the clone root as its working directory.

For the daily upload and build, save the following as `run_daily.sh` in the clone root. Replace the example dbt path with the result of `command -v dbt` on your machine.

```sh
#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
dbt_bin=/path/to/dbt

cd "$repo_dir"
"$repo_dir/.venv/bin/python" python/upload_sqlite.py
cd dbt
exec "$dbt_bin" build
```

Run `sh run_daily.sh` manually first. Then add an entry like this to the crontab of the account that can read the SQLite database and Snowflake credentials. Replace the example clone path. This example runs daily at 7:00 a.m. in the server’s configured time zone and appends output to a log.

```cron
0 7 * * * /bin/sh "/path/to/theme_park_waits/run_daily.sh" >> "/path/to/theme_park_waits/daily.log" 2>&1
```

Make any dbt environment variables available to the scheduled process. Run both processes on the same machine and point them to the same SQLite file on persistent storage.

## dbt model grain and metrics

| Model or layer | Grain and purpose |
| --- | --- |
| Staging | One model per raw table. Clean and type source fields and test keys and status values. |
| `_int_ride_parks` | One ride per snapshot. Join observations to snapshots for the park ID, then join park metadata for the name and time zone. |
| `_fct_ride_observations` | One ride per snapshot. This is the event-level fact for wait analysis. |
| `_int_daily_ride_wait` | One park, ride, and park-local date. Calculate eligible wait totals and observation counts. |
| `_fct_daily_park_performance` | One park per local date. Roll up the daily ride metrics into the dashboard table. |
| `_fct_daily_collection_health` | One park per UTC date. Report attempt counts and which recorded slots produced a snapshot. |

The observation grain preserves the original sampling frequency and supports both ride-level and park-level summaries. Park and ride identifiers are kept separate from labels and land assignments, which can change. A land ID can be empty for rides without a named land.

- **Average posted wait while open** uses polls where the ride was open and reported a nonnegative wait. An open zero counts. The result is empty when there are no eligible observations. These figures describe posted estimates sampled at poll times.
- **Park-wide average** divides total eligible wait minutes by the number of eligible observations, so each eligible poll has equal weight. Retain observation counts alongside averages to show how much data each result uses.
- **Park-local date** is derived from the poll timestamp and the park's time zone. The API's source update timestamp is kept separately for assessing freshness.
- **Collection health** counts attempts separately from slots. A failed attempt followed by a successful rerun can produce one failed attempt and one collected slot. Coverage of recorded slots omits periods when the collector wrote no attempt or snapshot at all. Comparing against an expected schedule would measure full coverage.

## Validation and next steps

Run `dbt build` to validate the configured models and tests. Check staging keys and relationships, then verify the mart has one row per park and local date. Check a park-day manually by dividing its total eligible wait minutes by its eligible observation count. After scheduling, check the task result or server log and confirm that a new snapshot reached Snowflake.

The full reload keeps the current daily job simple. As history grows, load new snapshots and their observations incrementally, with merge keys that make reruns safe. Advance the load checkpoint only after both tables succeed. Add a record of the last successful upload and compare collection with expected slots so a stopped collector can be distinguished from a failed warehouse load.

[Queue-Times API documentation](https://queue-times.com/pages/api)
