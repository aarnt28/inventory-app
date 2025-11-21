from sqlalchemy import inspect, text
from sqlalchemy.engine import Engine


def _add_column(engine: Engine, table: str, column_sql: str) -> None:
    with engine.begin() as conn:
        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {column_sql}"))


def ensure_inventory_columns(engine: Engine) -> None:
    """
    SQLite auto-migrations for InventoryItem. Adds missing columns if older DB files are present.
    """
    inspector = inspect(engine)
    try:
        existing = {col["name"] for col in inspector.get_columns("inventoryitem")}
    except Exception:
        # Table might not exist yet; create_all will handle it.
        return

    desired = {
        "barcode": "TEXT",
        "description": "TEXT",
        "quantity": "INTEGER DEFAULT 0",
        "sku": "TEXT",
        "image_url": "TEXT",
        "image_path": "TEXT",
    }

    missing = [name for name in desired if name not in existing]
    for name in missing:
        _add_column(engine, "inventoryitem", f"{name} {desired[name]}")
