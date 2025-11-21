import os
from pathlib import Path

from sqlmodel import SQLModel, Session, create_engine

from .utils.paths import resolve_data_dir
from .utils.migrations import ensure_inventory_columns


def _sqlite_url() -> str:
    # Allow overriding the DB file (Windows users can pass a full path such as c:/data/inventory.db)
    explicit = os.getenv("DB_PATH")
    if explicit:
        return explicit

    data_dir = resolve_data_dir()
    return f"sqlite:///{data_dir / 'inventory.db'}"


sqlite_url = _sqlite_url()

# Ensure the directory exists for SQLite file targets
if sqlite_url.startswith("sqlite:///"):
    db_file = sqlite_url.replace("sqlite:///", "", 1)
    db_dir = Path(db_file).parent
    if db_dir and not db_dir.exists():
        db_dir.mkdir(parents=True, exist_ok=True)

engine = create_engine(
    sqlite_url,
    connect_args={"check_same_thread": False}  # Needed for SQLite + FastAPI
)


def init_db():
    SQLModel.metadata.create_all(engine)
    # For existing SQLite files, auto-add any new columns we expect
    ensure_inventory_columns(engine)


def get_session():
    """
    FastAPI dependency that yields a SQLModel Session bound to the shared engine.
    """
    with Session(engine) as session:
        yield session
