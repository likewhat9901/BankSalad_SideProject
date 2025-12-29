from pathlib import Path
from config import APP_DIR

# project root
_APP_DIR: Path = APP_DIR

# directories
_COMMON_DIR: Path = _APP_DIR / "common"
_DOMAINS_DIR: Path = _APP_DIR / "domains"


FILE_PATHS: dict[str, Path] = {
    "overspending_rules": _DOMAINS_DIR / "overspending" / "config" / "overspending_rules.json",
}