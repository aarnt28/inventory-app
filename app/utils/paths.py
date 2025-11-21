import os
from pathlib import Path


def resolve_data_dir() -> Path:
    """
    Resolve the base data directory (defaults to ./data) and ensure it exists.
    """
    base = Path(os.getenv("DATA_DIR", "data")).resolve()
    base.mkdir(parents=True, exist_ok=True)
    return base


def resolve_upload_dir() -> Path:
    """
    Resolve where uploaded files should be stored and ensure the folder exists.
    """
    override = os.getenv("UPLOAD_DIR")
    if override:
        target = Path(override).resolve()
    else:
        target = resolve_data_dir() / "uploads"

    target.mkdir(parents=True, exist_ok=True)
    return target
