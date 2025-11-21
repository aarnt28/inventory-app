Here is a clean, direct, **agents.md** file you can drop straight into your repo.
It captures the architecture, objectives, stack decisions, and the development path we agreed upon.

No fluff — this is the scaffolding file that keeps you and any future contributor aligned.

---

# **agents.md**

# **Project: Inventory Management System (Phase 1 – SQLite, FastAPI, SQLModel, SQLAdmin)**

## **Purpose**

This project provides a lightweight, self-hosted inventory management backend designed for personal use and occasional automation. It supports rapid schema evolution, low-friction data entry (via iOS/iPadOS Shortcuts), and a temporary GUI for database exploration during early development.

The long-term plan is to evolve this into a production-grade backend, optionally migrating to PostgreSQL and adding a polished frontend UI. Phase 1 prioritizes simplicity, adaptability, and low operational overhead.

---

# **Core Objectives**

### **1. Backend API**

Provide a FastAPI-based backend with routes to:

* Manage items (read, create, update, delete)
* Log inventory transactions (add, remove, use)
* Capture quick updates from Shortcuts (timestamp, device ID, metadata)
* Serve as data source for future iOS app

### **2. Database Layer**

Use SQLModel with SQLite during Phase 1 to allow:

* Zero-overhead local development
* Easy schema evolution while models are still changing
* A single-file database (`inventory.db`)
* Future migration path to PostgreSQL by swapping the engine URL

Phase 2 allows migration to PostgreSQL when concurrency, volume, or multi-user demands increase.

### **3. Temporary GUI Admin Layer**

A development-only admin interface using **SQLAdmin**:

* Live table visualization
* CRUD for items and transactions
* Browsing relationships and schema structure
* Safe to remove later without affecting the API layer
* Available at `/admin`

This acts as scaffolding while the system is evolving.

### **4. Future Frontend UI**

A polished, user-facing web UI will eventually:

* Live at `/`
* Support browsing/editing items
* Support dashboards and usage summaries
* Replace SQLAdmin completely
* Integrate cleanly with the REST API

Not required for Phase 1.

### **5. Automation-Friendly Design**

API endpoints will be optimized for:

* iOS/iPadOS Shortcuts
* One-tap “quick log” actions
* Minimal required fields for transactions
* Automatic timestamps
* Optional device ID capture
* Ability to fill in additional details later

This supports real-world field work where speed > completeness.

---

# **Architecture Overview**

### **Stack**

* **FastAPI**
* **SQLModel**
* **SQLite** (Phase 1) → PostgreSQL (optional Phase 2)
* **SQLAdmin** (temporary GUI)
* **Docker + docker-compose**
* **uvicorn** ASGI server

### **Directory Structure**

```
app/
  main.py
  database.py
  admin.py
  models/
    inventory_item.py
    transaction.py
  routers/
    items.py
    transactions.py
  schemas/
    item.py
    transaction.py
inventory.db        # SQLite file (mounted via Docker)
Dockerfile
docker-compose.yaml
requirements.txt
```

---

# **Phase Breakdown**

## **Phase 1 — Foundational Build**

**Goals:**

* Implement SQLite-backed SQLModel database
* Add InventoryItem + Transaction models
* Add CRUD API endpoints
* Implement SQLAdmin UI for table visualization
* Deploy via Docker
* Create minimum viable Shortcut workflows

**Deliverables:**

* Working FastAPI app at port 8000
* Admin panel at `/admin`
* `/api/items` and `/api/transactions` functional
* iOS Shortcut for creating transaction entries

---

## **Phase 2 — Data Maturity**

**Optional upgrade**

* Add Alembic migrations
* Add relationships (categories, vendors, locations)
* Add audit logging and constraints
* Improve API structure (pagination, filtering)
* Add API authentication (API key or session token)
* Add reporting endpoints

---

## **Phase 3 — Frontend UI**

Replace SQLAdmin with a custom interface:

* Built with your choice (Jinja2, Vue, React, Svelte, SwiftUI front-end, etc.)
* Allows full user experience for browsing + updating items
* Provides dashboards for usage, stock levels, and trends

---

## **Phase 4 — PostgreSQL Migration (Optional)**

Recommended only if:

* Multiple concurrent users become common
* Transaction volume grows significantly
* You need complex queries or indexing strategies

Migration path:

* Move SQLite → Postgres via Alembic
* Update database URL
* Redeploy container with PostgreSQL service

---

# **Guiding Principles**

1. **Start simple, stay flexible.**
   SQLite keeps early development friction-free.

2. **Admin UI is temporary scaffolding.**
   SQLAdmin helps you shape the data model but is not meant for end-users.

3. **API-first architecture.**
   Everything—Shortcuts, future apps, UI—consumes the same endpoints.

4. **Automations must be frictionless.**
   Quick logging > full-detail entry during field work.

5. **Migration paths stay clean.**
   The project is designed so you can switch to PostgreSQL without rewriting models.

6. **Continously Update README.md as changes are applied and functionality upgraded/improved/modified.

---

# **Next Actions for Agents (Development Tasks)**

### **1. Initialize repo & directory structure**

* Scaffold the folders exactly as listed
* Add initial files for `main.py`, models, routers, admin, and database engine

### **2. Implement initial SQLModel models**

* InventoryItem
* Transaction

### **3. Build SQLite engine**

* `inventory.db` created automatically on startup
* File mounted to host via Docker volume

### **4. Build API endpoints**

* `/api/items`
* `/api/transactions`

### **5. Integrate SQLAdmin**

* Register models
* Verify CRUD functionality through `/admin`

### **6. Containerize the app**

* Dockerfile
* docker-compose.yaml
* Persistent volume for SQLite file

### **7. Build first Shortcut**

* “Quick Add Inventory Transaction”
* Fields: amount, type, item_id, device_id

### **8. Begin iterative schema improvements**

* Add fields
* Restructure tables
* Expand relationships
* Validate UI changes via SQLAdmin until ready to replace it

---

# **Status**

**Phase 1 — READY FOR IMPLEMENTATION**

Once this scaffolding is live, the system is usable and ready to expand.

---

If you'd like, I can also generate:

* A `README.md`
* A `tasks.md` sprint board
* The starter API documentation file
* The first Shortcut (JSON export)
* ERD diagram for your current schema
* Swagger tagging structure for your endpoints

Just say what you want next.
