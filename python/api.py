"""Small standard-library client for the public Queue-Times API."""
import json
import logging
import time
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

BASE_URL = "https://queue-times.com"


def get_json(path, attempts=3):
    request = Request(BASE_URL + path, headers={
        "User-Agent": "ThemeParkWaitsResearch/0.1",
        "Accept": "application/json",
    })
    for attempt in range(attempts):
        delay = 2 ** attempt
        try:
            with urlopen(request, timeout=30) as response:
                return json.load(response)
        except HTTPError as error:
            if error.code not in (429, 500, 502, 503, 504):
                raise
            retry_after = error.headers.get("Retry-After")
            if retry_after:
                try:
                    delay = float(retry_after)
                except ValueError:
                    delay = (parsedate_to_datetime(retry_after)
                             - datetime.now(timezone.utc)).total_seconds()
                # Do not retry earlier than a long server-requested delay.
                if delay > 60:
                    raise
        except (URLError, TimeoutError, OSError):
            if attempt == attempts - 1:
                raise
        if attempt == attempts - 1:
            raise RuntimeError(f"Request failed after {attempts} attempts: {path}")
        logging.warning("Retrying %s in %.1fs", path, max(0, delay))
        time.sleep(max(0, delay))


def get_parks():
    groups = get_json("/parks.json")
    return [{**park, "group_id": group["id"], "group_name": group["name"]}
            for group in groups for park in group["parks"]]


def get_wait_times(park_id):
    return get_json(f"/parks/{park_id}/queue_times.json")
