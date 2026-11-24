import os
import sqlite3
import tempfile
from contextlib import closing
from pathlib import Path

import pandas as pd
import snowflake.connector
from dotenv import load_dotenv
from snowflake.connector.pandas_tools import write_pandas

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SOURCE_DB = PROJECT_ROOT / "data" / "wait_times.sqlite3"

TABLES = (
    "parks",
    "catalog_cache",
    "snapshots",
    "wait_observations",
    "poll_attempts",
)


def main():
    load_dotenv(PROJECT_ROOT / ".env") #load env variables

    if not SOURCE_DB.is_file():
        raise FileNotFoundError(f"Database not found: {SOURCE_DB}")

    with tempfile.TemporaryDirectory() as temp_dir:
        snapshot = Path(temp_dir) / "wait_times.db"
        source_uri = SOURCE_DB.resolve().as_uri() + "?mode=ro" #read-only

        # Take a consistent backup while the collector can keep running.
        with (
            closing(sqlite3.connect(source_uri, uri=True)) as source,
            closing(sqlite3.connect(snapshot)) as backup,
        ):
            source.backup(backup) #copies the entire database into backup

        with (
            closing(sqlite3.connect(snapshot)) as sqlite_conn,
            snowflake.connector.connect( #connects to snowflake!!
                account=os.environ["SNOWFLAKE_ACCOUNT"],
                user=os.environ["SNOWFLAKE_USER"],
                password=os.environ["SNOWFLAKE_PASSWORD"],
                warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
                database=os.environ["SNOWFLAKE_DATABASE"],
                schema=os.environ["SNOWFLAKE_SCHEMA"],
                role=os.environ["SNOWFLAKE_ROLE"],
            ) as snowflake_conn,
        ):
            with snowflake_conn.cursor() as cursor: #cursor is an object that manipulates/retrieves data
                cursor.execute("""
                    SELECT table_name
                    FROM information_schema.tables
                    WHERE table_schema = CURRENT_SCHEMA()
                """)
                existing_tables = {name for (name,) in cursor.fetchall()}

            for table in TABLES:
                df = pd.read_sql_query(f'SELECT * FROM "{table}"', sqlite_conn)
                df.columns = df.columns.str.upper()

                target = table.upper()
                table_exists = target in existing_tables

                if df.empty and not table_exists:
                    raise RuntimeError(
                        f"{table} is empty. Create {target} in Snowflake "
                        "with explicit column types or run again once it has data."
                    )

                success, _, rows_loaded, _ = write_pandas(
                    snowflake_conn,
                    df,
                    table_name=target,
                    auto_create_table=not table_exists,
                    overwrite=table_exists,
                )

                if not success or rows_loaded != len(df):
                    raise RuntimeError(
                        f"{target}: loaded {rows_loaded:,} of {len(df):,} rows"
                    )

                print(f"{target}: loaded {rows_loaded:,} rows")


if __name__ == "__main__":
    main()