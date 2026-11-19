import sqlite3
import tempfile
from contextlib import closing
from pathlib import Path
import requests
from urllib.parse import quote

from databricks.sdk import WorkspaceClient
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent

load_dotenv(PROJECT_ROOT / ".env")

SOURCE_DB = PROJECT_ROOT / "data" / "wait_times.sqlite3"

DESTINATION = ("/Volumes/deng_accelerator/raw_data/sqlite_uploads/wait_times.db")

def main():
    if not SOURCE_DB.is_file():
        raise FileNotFoundError(f"Database not found: {SOURCE_DB}")

    client = WorkspaceClient() #initializes a client using our env variables
    print("Connected as:", client.current_user.me().user_name)

    print("Checking destination...")

    for item in client.files.list_directory_contents(
        "/Volumes/deng_accelerator/raw_data/sqlite_uploads"
    ):
        print(item.path)

    print("Destination listing succeeded")

    with tempfile.TemporaryDirectory() as temp_dir: #define a temporary directory
        snapshot = Path(temp_dir) / "wait_times.db" #local backup file

        source_uri = SOURCE_DB.resolve().as_uri() + "?mode=ro" #opens a read-only copy of the original db

        with closing(
            sqlite3.connect(source_uri, uri=True)
        ) as source:

            with closing(
                sqlite3.connect(snapshot)
            ) as target:

                source.backup(target) #copies the contents of source into our backup file

        #with snapshot.open("rb") as contents: #'rb' is for 'read binary'
            #client.files.upload(
                #file_path=DESTINATION,
                #contents=contents,
                #overwrite=True,
            #)
        
        file_size = snapshot.stat().st_size
        print(f"Uploading {file_size / 1024 / 1024:.2f} MB...")

        url = (
            client.config.host.rstrip("/")
            + "/api/2.0/fs/files"
            + quote(DESTINATION, safe="/")
        )

        headers = dict(client.config.authenticate())
        headers["Content-Type"] = "application/octet-stream"
        headers["Content-Length"] = str(file_size)

        with snapshot.open("rb") as contents:
            response = requests.put(
                url,
                headers=headers,
                params={"overwrite": "true"},
                data=contents,
                timeout=(15, 120),
            )

        print("Upload status:", response.status_code)

        if not response.ok:
            print(response.text)

        response.raise_for_status()
        print(f"Uploaded database to {DESTINATION}")


        

if __name__ == "__main__":
    main()