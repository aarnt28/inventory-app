# Inventory Management API

FastAPI + SQLModel backend for tracking inventory items and their transactions. The service ships with a lightweight SQLite database, automatic column backfills for existing database files, and a temporary SQLAdmin UI for quick data inspection.

## Features
- CRUD API for inventory items, including optional image uploads or external image URLs.
- Transaction logging that records adds/uses/adjustments with optional device, vendor/client, and shortcut metadata.
- Static hosting of uploaded images under `/uploads` for easy previewing from API responses.
- SQLAdmin dashboard at `/admin` for browsing and editing data during early development.
- Environment-driven data directories to keep SQLite files and uploads outside the container image.

## Project Structure
- `app/main.py` – FastAPI app wiring, startup hooks, and router registration.
- `app/database.py` – SQLite engine creation, data directory resolution, and auto-migration helper.
- `app/models/` – SQLModel tables for `InventoryItem` and `Transaction` with relationships.
- `app/routers/` – API endpoints for items and transactions.
- `app/utils/` – Helpers for resolving data/upload paths and patching missing columns in existing DB files.
- `docker-compose.yml` – Container setup with bind-mounted data volume for persistence.

## Getting Started
### Local (Python)
1. Create a virtual environment and install dependencies:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```
2. Run the API with auto-reload:
   ```bash
   uvicorn app.main:app --reload
   ```
3. Open the interactive docs at `http://localhost:8000/docs`.

### Docker
1. Build and start the service:
   ```bash
   docker-compose up --build
   ```
2. SQLite data and uploads are persisted to `./data` by default (override with `DATA_DIR`).

## Configuration
- `DATA_DIR` – Base directory for SQLite and uploads (defaults to `./data`).
- `UPLOAD_DIR` – Optional override for uploads directory (defaults to `DATA_DIR/uploads`).
- `DB_PATH` – Full SQLAlchemy database URL; defaults to `sqlite:///<DATA_DIR>/inventory.db`.

Uploads are stored under `/uploads` inside the FastAPI app and mounted to the host via `DATA_DIR`. The server ensures these directories exist at startup.

## API Overview
### Items (`/api/items`)
- `GET /api/items/` – List items with `preview_url` pointing to an upload or external image.
- `POST /api/items/` – Create an item via form fields (`name`, `barcode`, optional `description`, `quantity`, `sku`, `image_url`) and optional `image_file` upload. `image_url` and `image_file` cannot both be provided.
- `GET /api/items/{barcode}` – Retrieve a single item by barcode.
- `PATCH /api/items/{barcode}` – Update mutable fields (partial updates supported).
- `DELETE /api/items/{barcode}` – Remove an item.

### Transactions (`/api/transactions`)
- `GET /api/transactions/` – List all transactions (includes the related item barcode).
- `POST /api/transactions/` – Create a transaction using JSON payload: `barcode`, `amount`, `type`, and optional `unit_cost`, `device_id`, `vendor_client`, `notes`, `trans_source` (defaults to `shortcut`).
- `GET /api/transactions/{id}` – Retrieve a transaction by ID.
- `PATCH /api/transactions/{id}` – Update transaction fields; supplying `barcode` re-associates the transaction to another item.
- `DELETE /api/transactions/{id}` – Remove a transaction.

### Admin UI
SQLAdmin is available at `/admin` for quick CRUD over inventory items and transactions. It uses the same database connection defined in `app/database.py`.

## Data & Migrations
The app auto-creates SQLite tables on startup and backfills missing `InventoryItem` columns for existing databases (e.g., `barcode`, `description`, `quantity`, `sku`, `image_url`, `image_path`). This keeps older `inventory.db` files compatible without manual migrations during early development.

## Development Notes
- Uploaded file previews are served from `/uploads/<filename>`.
- Barcode uniqueness is enforced at both the application and database level.
- The codebase targets SQLite for Phase 1 but is structured to swap to PostgreSQL later by changing `DB_PATH`.
