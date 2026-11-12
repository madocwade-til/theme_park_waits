import json
from pathlib import Path

from api import get_parks

config_path = Path(__file__).parent / "config.json"

config = json.loads(config_path.read_text(encoding="utf-8"))

config["park_ids"] = sorted({
    park["id"] for park in get_parks()
})

config_path.write_text(
    json.dumps(config, indent=2),
    encoding="utf-8",
)

print(f"Configured collection for {len(config['park_ids'])} parks.")